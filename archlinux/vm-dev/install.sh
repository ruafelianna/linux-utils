PARTITION_EFI='c12a7328-f81f-11d2-ba4b-00a0c93ec93b'
PARTITION_LINUX_SWAP='0657fd6d-a4ab-43c4-84e5-0933c84b4f4f'
PARTITION_LINUX_EXT4='0fc63daf-8483-4772-8e79-3d69d8477de4'

{
    source ./archlinux/vm-dev/env.sh && \

    echo $ECHO_START'Loading locale settings...' && \
    source $BASE_DIR/env-locale.sh && \

    echo $ECHO_START'Loading proxy settings...' && \
    source ./.bashrc.d/proxy.sh
} && \

$BASE_DIR/locale.sh && \

{
    echo $ECHO_START'Creating partitions...' && \
    sfdisk /dev/sda << EOF
label: gpt
/dev/sda1: start=2048, size=2097152, type=$PARTITION_EFI
/dev/sda2: start=2099200, size=8388608, type=$PARTITION_LINUX_SWAP
/dev/sda3: start=10487808, type=$PARTITION_LINUX_EXT4
EOF
} && \

{
    echo $ECHO_START'Formatting boot partition...' && \
    mkfs.vfat -n BOOT /dev/sda1 && \

    echo $ECHO_START'Formatting swap partition...' && \
    mkswap -L SWAP /dev/sda2 && \

    echo $ECHO_START'Formatting root partition...' && \
    yes | mkfs.ext4 -L ROOT /dev/sda3
} && \

{
    echo $ECHO_START'Mounting swap...' && \
    swapon /dev/sda2 && \

    echo $ECHO_START'Mounting root...' && \
    mount /dev/sda3 /mnt && \

    echo $ECHO_START'Mounting boot...' && \
    mount --mkdir /dev/sda1 /mnt/boot
} && \

{
    echo $ECHO_START'Updating pacman mirror list...' && \
    reflector --country "$COUNTRY," --save /etc/pacman.d/mirrorlist && \

    echo $ECHO_START'Updating pacman repository information...' && \
    pacman -Syy && \

    echo $ECHO_START'Initializing pacman keys...' && \
    pacman-key --init && \

    echo $ECHO_START'Populating pacman keys...' && \
    pacman-key --populate && \

    echo $ECHO_START'Installing base system...' && \
    pacstrap -K /mnt base sudo which virtualbox-guest-utils \
        git openssh nano tree refind dhcpcd \
        terminus-font docker docker-compose python-pdm
} && \

{
    echo $ECHO_START'Generating stab...' && \
    genfstab -U /mnt >> /mnt/etc/fstab
} && \

{
    echo $ECHO_START'Creating installation dir on mnt...' && \
    mkdir -p /mnt/install/archlinux

    echo $ECHO_START'Copying installation files to mnt...' && \
    cp -r ./.bashrc.d ./.nanorc /mnt/install && \
    cp -r $BASE_DIR /mnt/install/archlinux && \

    echo $ECHO_START'Changing root to /mnt...' && \
    arch-chroot /mnt bash -c "cd /install && source $BASE_DIR/chroot-install.sh"
} && \

{
  echo $ECHO_START'Removing installation files...' && \
  rm -r /mnt/install && \

  echo $ECHO_START'Unmounting root and boot...' && \
  umount -R /mnt && \

  echo $ECHO_START'Unmounting swap...' && \
  swapoff /dev/sda2 && \

  echo 'Installation has completed. Extract installation media and reboot...'
}
