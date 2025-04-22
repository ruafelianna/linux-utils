#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$SCRIPT_DIR/common.sh"

# ENV

log 'Loading proxy settings...'
source ./.bashrc.d/proxy.sh

log 'Loading locale settings...'
source $SCRIPT_DIR/env-locale.sh

log 'Loading chroot settings...'
source $SCRIPT_DIR/env-chroot.sh

# LOCALE

log 'Loading keys...'
loadkeys $KEYMAP

log 'Setting font...'
setfont $FONT

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

# PARTITIONS

log 'Creating partitions...'
sfdisk /dev/sda << EOF
label: gpt
/dev/sda1: start=2048, size=2097152, type=$PARTITION_EFI
/dev/sda2: start=2099200, size=8388608, type=$PARTITION_LINUX_SWAP
/dev/sda3: start=10487808, type=$PARTITION_LINUX_EXT4
EOF

log 'Formatting boot partition...'
mkfs.vfat -n BOOT /dev/sda1

log 'Formatting swap partition...'
mkswap -L SWAP /dev/sda2

log 'Formatting root partition...'
yes | mkfs.ext4 -L ROOT /dev/sda3

log 'Mounting swap...'
swapon /dev/sda2

log 'Mounting root...'
mount /dev/sda3 /mnt

log 'Mounting boot...'
mount --mkdir /dev/sda1 /mnt/boot

# PKGS

log 'Updating pacman mirror list...'
reflector --country "$COUNTRY," --save /etc/pacman.d/mirrorlist

log 'Updating pacman repository information...'
pacman -Syy

log 'Initializing pacman keys...'
pacman-key --init

log 'Populating pacman keys...'
pacman-key --populate

log 'Installing base system...'
pacstrap -K /mnt base sudo which virtualbox-guest-utils \
    git openssh nano tree refind dhcpcd \
    terminus-font docker docker-compose python-pdm

# STAB

log 'Generating stab...'
genfstab -U /mnt >> /mnt/etc/fstab

# CHROOT

INSTALL_DIR=/mnt/install
SCRIPTS_DIR=$INSTALL_DIR/scripts

log 'Creating installation dir on /mnt...'
mkdir -p $INSTALL_DIR

log 'Copying installation files to /mnt...'
cp -r ./.bashrc.d ./.nanorc $SCRIPT_DIR $INSTALL_DIR
cp -r $SCRIPT_DIR $SCRIPTS_DIR

log 'Changing root to /mnt...'
arch-chroot /mnt bash -c "cd /install && source ./scripts/chroot-install.sh"

# FINISH

log 'Removing installation files...'
rm -r $INSTALL_DIR

log 'Unmounting root and boot...'
umount -R /mnt

log 'Unmounting swap...'
swapoff /dev/sda2

log 'Installation has completed. Extract installation media and reboot...'
