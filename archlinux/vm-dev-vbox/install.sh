#!/bin/bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "$SCRIPT_DIR/env.sh"

yes | scp -P $VM_PORT -r ../../../linux-utils/ root@$VM_HOST:/root
yes | ssh -p $VM_PORT root@$VM_HOST "cd linux-utils && ./archlinux/vm-dev/install.sh"
