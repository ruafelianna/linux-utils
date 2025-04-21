export BASE_DIR=/install/archlinux/vm-dev

{
    source ./archlinux/vm-dev/env.sh && \

    echo $ECHO_START'Loading locale settings...' && \
    source $BASE_DIR/env-locale.sh

    echo $ECHO_START'Loading chroot settings...' && \
    source $BASE_DIR/env-chroot.sh
} && \

$BASE_DIR/locale.sh && \

{
    echo $ECHO_START'Setting timezone...' && \
    ln -s "/usr/share/zoneinfo/$TZ" /etc/localtime && \

    echo $ECHO_START'Syncing clock...' && \
    hwclock --systohc
} && \

{
    echo $ECHO_START'Setting host name...' && \
    echo $COMPUTER_NAME > /etc/hostname && \

    echo $ECHO_START'Setting hosts...' && \
    cat >> /etc/hosts << EOF
127.0.0.1       localhost
::1             localhost
127.0.1.1       $COMPUTER_NAME.local    $COMPUTER_NAME
EOF
} && \

{
    docker_dir=/etc/docker && \

    echo $ECHO_START'Creating docker folder...' && \
    mkdir -p $docker_dir && \

    echo $ECHO_START'Creating docker proxy settings...' && \
    cat > $docker_dir/daemon.json << EOF
{
  "proxies": {
    "http-proxy": "$http_proxy",
    "https-proxy": "$https_proxy",
    "no-proxy": "$no_proxy"
  }
}
EOF
} && \

{
    echo $ECHO_START'Setting root password...' && \
    echo -n $ROOT_PASSWD | passwd -s && \

    echo $ECHO_START'Creating administrator user...' && \
    useradd -G wheel,docker -s /bin/bash -m $USER_NAME && \

    echo $ECHO_START'Setting admiinistrator password...' && \
    echo -n $USER_PASSWD | passwd -s $USER_NAME && \

    whl='%wheel ALL=(ALL:ALL) ALL' && \

    echo $ECHO_START'Setting wheel users as sudoers...' && \
    sed -i "s/# $whl/$whl/" /etc/sudoers
} && \

{
    customize_user() {
        home=$1 && \
        home_d=$home/.bashrc.d && \

        echo $ECHO_START'Copying nano files...' && \
        cp ./.nanorc $home && \

        echo $ECHO_START'Creating bashrc folder...' && \
        mkdir -p $home_d && \

        echo $ECHO_START'Copying bash files...' && \
        cp ./bashrc.d/{colors,prompt,proxy}.sh $home_d && \

        echo $ECHO_START'Uncommenting bashrc corner settings...' && \
        sed -i '15,16 s/# //' $home_d/prompt.sh && \

        echo $ECHO_START'Uncommenting bashrc PS1 var...' && \
        sed -i "$2 s/# //" $home_d/prompt.sh && \

        echo $ECHO_START'Changing nanorc directory...' && \
        sed -i '224 s/local\///' $home/.nanorc && \

        echo $ECHO_START'Uncommenting nanorc color settings...' && \
        sed -i "$3 s/# //" $home/.nanorc && \

        echo $ECHO_START'Adding prompt sourcing...' && \
        echo 'source $HOME/.bashrc.d/prompt.sh' >> $home/.bashrc && \

        echo $ECHO_START'Adding proxy sourcing...' && \
        echo 'source $HOME/.bashrc.d/proxy.sh' >> $home/.bashrc
    }

    echo $ECHO_START'Adding root customization...' && \
    customize_user '/root' '22' '210,217' && \

    echo $ECHO_START'Adding administrator customization...' && \
    customize_user "/home/$USER_NAME" '19' '201,208' && \

    echo $ECHO_START'Creating root .bash_profile...' && \
    echo '[[ -f ~/.bashrc ]] && . ~/.bashrc' > /root/.bash_profile && \

    echo $ECHO_START'Changing owner of administrator files...' && \
    chown -R $USER_NAME:$USER_NAME $home
} && \

{
    echo $ECHO_START'Enabling dhcp daemon...' && \
    systemctl enable dhcpcd && \

    echo $ECHO_START'Enabling docker daemon...' && \
    systemctl enable docker
} && \

{
    echo $ECHO_START'Installing refind...' && \
    refind-install && \

    root_uuid=$(lsblk -o UUID /dev/sda3 | sed -n '2 s/0/0/p') && \

    echo $ECHO_START'Creating refind conf...' && \
    cat > /boot/refind_linux.conf << EOF
"Boot with standard options"  "root=UUID=$root_uuid rw loglevel=3 quiet"
"Boot to single-user mode"    "root=UUID=$root_uuid rw loglevel=3 quiet single"
"Boot with minimal options"   "root=UUID=$root_uuid ro"
EOF
}
