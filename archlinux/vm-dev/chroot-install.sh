#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$SCRIPT_DIR/common.sh"

# ENV

log 'Loading proxy settings...'
source ./.bashrc.d/proxy.sh

log 'Loading locale settings...'
source "$SCRIPT_DIR/env-locale.sh"

log 'Loading desktop settings...'
source "$SCRIPT_DIR/env-desktop.sh"

log 'Loading git settings...'
source "$SCRIPT_DIR/env-git.sh"

log 'Loading chroot settings...'
source "$SCRIPT_DIR/env-chroot.sh"

# LOCALE

for locale in "${LOCALES[@]}"
do
    l="$locale.UTF-8 UTF-8"

    log "Uncommenting locale: $l..."
    sed -i "s/#$l/$l/" /etc/locale.gen
done

log 'Generating locale...'
locale-gen

log 'Setting language...'
echo "LANG=$LOCALE.UTF-8" > /etc/locale.conf

log 'Setting console settings...'
cat > /etc/vconsole.conf << EOF
KEYMAP=$KEYMAP
FONT=$FONT
EOF

# TIME

log 'Setting timezone...'
ln -s "/usr/share/zoneinfo/$TZ" /etc/localtime

log 'Syncing clock...'
hwclock --systohc

# NETWORK

log 'Setting host name...'
echo $COMPUTER_NAME > /etc/hostname

log 'Setting hosts...'
cat >> /etc/hosts << EOF
127.0.0.1       localhost
::1             localhost
127.0.1.1       $COMPUTER_NAME.local    $COMPUTER_NAME
EOF

# DOCKER

docker_dir=/etc/docker

log 'Creating docker folder...'
mkdir -p $docker_dir

log 'Creating docker proxy settings...'
cat > $docker_dir/daemon.json << EOF
{
  "proxies": {
    "http-proxy": "$http_proxy",
    "https-proxy": "$https_proxy",
    "no-proxy": "$no_proxy"
  }
}
EOF

# YAY

log 'Cloning yay repository'
git clone https://aur.archlinux.org/yay.git

log 'Installing yay'
cd yay && makepkg -si

log 'Removing yay repository'
cd .. && rm -rf yay

log 'Installing yaycache...'
yes | yay -S yaycache

# DESKTOP YAY APPS

if [ -n "$DESKTOP_ENVIRONMENT" ]; then
    log "Installing vscode..."
    yes | yay -S visual-studio-code-bin
fi

# USERS

log 'Setting root password...'
echo -n $ROOT_PASSWD | passwd -s

log 'Creating administrator user...'
useradd -G wheel,docker,vboxsf -s /bin/bash -m $USER_NAME

log 'Setting admiinistrator password...'
echo -n $USER_PASSWD | passwd -s $USER_NAME

whl='%wheel ALL=(ALL:ALL) ALL'

log 'Setting wheel users as sudoers...'
sed -i "s/# $whl/$whl/" /etc/sudoers

# CUSTOMIZATION

customize_user() {
    home=$1
    home_d=$home/.bashrc.d

    log 'Copying nano files...'
    cp ./.nanorc $home

    log 'Creating bashrc folder...'
    mkdir -p $home_d

    log 'Copying bash files...'
    cp ./.bashrc.d/{colors,prompt,proxy}.sh $home_d

    log 'Uncommenting bashrc corner settings...'
    sed -i '15,16 s/# //' $home_d/prompt.sh

    log 'Uncommenting bashrc PS1 var...'
    sed -i "$2 s/# //" $home_d/prompt.sh

    log 'Changing nanorc directory...'
    sed -i '224 s/local\///' $home/.nanorc

    log 'Uncommenting nanorc color settings...'
    sed -i "$3 s/# //" $home/.nanorc

    log 'Adding .bashrc.d sourcing...'
    cat >> $home/.bashrc << 'EOF'
source $HOME/.bashrc.d/prompt.sh
source $HOME/.bashrc.d/proxy.sh
EOF
}

root_home='/root'
user_home="/home/$USER_NAME"

log 'Adding root customization...'
customize_user "$root_home" '22' '210,217'

log 'Adding administrator customization...'
customize_user "$user_home" '19' '201,208'

log 'Creating root .bash_profile...'
echo '[[ -f ~/.bashrc ]] && . ~/.bashrc' > /root/.bash_profile

log 'Creating user ssh folder...'
mkdir -p "$user_home/.ssh"

log 'Copying ssh public key to user ssh folder...'
cp ./authorized_keys "$user_home/.ssh"

log 'Creating user ssh config...'
cat > "$user_home/.ssh/config" << EOF
ProxyCommand nc -X connect -x $HTTPS_PROXY %h %p
EOF

log 'Creating user ssh key...'
ssh-keygen -t ed25519 -C "$USER_NAME" -f $user_home/.ssh/id_ed25519

log 'Adding keep proxy envvars command to sudoers file...'
cat >> /etc/sudoers << EOF
Defaults env_keep += "http_proxy https_proxy no_proxy HTTP_PROXY HTTPS_PROXY NO_PROXY"
EOF

log 'Adding user git config...'
cat > "$user_home/.gitconfig" << EOF
[init]
	defaultBranch = $GIT_DEFAULT_BRANCH
[core]
	editor = $GIT_EDITOR
[user]
	email = $GIT_USER_EMAIL
	name = $GIT_USER_NAME
[http]
	proxy = $HTTPS_PROXY
EOF

log 'Changing owner of administrator files...'
chown -R $USER_NAME:$USER_NAME "$user_home"

# DAEMONS

log 'Enabling dhcp daemon...'
systemctl enable dhcpcd

log 'Enabling ssh daemon...'
systemctl enable sshd

log 'Enabling docker daemon...'
systemctl enable docker

log 'Enabling vbox daemon...'
systemctl enable vboxservice

if [ -n "$DISPLAY_MANAGER" ]; then
    log "Enabling $DISPLAY_MANAGER daemon..."
    systemctl enable "$DISPLAY_MANAGER"
fi

# BOOTLOADER

log 'Installing refind...'
refind-install

log 'Getting root partition uuid'
root_uuid=$(lsblk -o UUID /dev/sda3 | sed -n '2 s/0/0/p')

log 'Creating refind conf...'
cat > /boot/refind_linux.conf << EOF
"Boot with standard options"  "root=UUID=$root_uuid rw loglevel=3 quiet"
"Boot to single-user mode"    "root=UUID=$root_uuid rw loglevel=3 quiet single"
"Boot with minimal options"   "root=UUID=$root_uuid ro"
EOF
