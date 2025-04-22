#!/bin/bash
set -e

PARTITION_EFI='c12a7328-f81f-11d2-ba4b-00a0c93ec93b'
PARTITION_LINUX_SWAP='0657fd6d-a4ab-43c4-84e5-0933c84b4f4f'
PARTITION_LINUX_EXT4='0fc63daf-8483-4772-8e79-3d69d8477de4'

log() {
    echo ">>> $1"
}

log_var_error() {
    log "Error: $1 var is not defined in $2"
}
