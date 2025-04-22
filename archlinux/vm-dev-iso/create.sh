#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

log() {
    echo '>>> '"$1"
}

log "Loading environment..."
source "$SCRIPT_DIR"/env.sh

log "Installing required packages..."
sudo pacman -Sy --needed --noconfirm arch-install-scripts awk dosfstools \
    e2fsprogs erofs-utils findutils grub gzip libarchive libisoburn mtools \
    openssl pacman sed squashfs-tools

log "Cloning archiso repository..."
git clone https://github.com/archlinux/archiso

ARCHISO=./archiso
SSH_DIR=$ARCHISO/configs/releng/airootfs/root/.ssh

log "Creating ssh dir..."
mkdir -p $SSH_DIR
chmod 700 $SSH_DIR

log "Creating authorized_keys..."
echo "$PUBLIC_KEY" >> $SSH_DIR/authorized_keys
chmod 600 $SSH_DIR/authorized_keys

log "Creating archiso..."
sudo $ARCHISO/archiso/mkarchiso -w $ARCHISO/work -o "$OUT_DIR" $ARCHISO/configs/releng/

log "Removing temporary files..."
sudo rm -r $ARCHISO

log "Archiso is created successfully in $OUT_DIR"
