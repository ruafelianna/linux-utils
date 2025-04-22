COMPUTER_NAME=

ROOT_PASSWD=
USER_NAME=
USER_PASSWD=

chroot_env='env-chroot.sh'

if [ -z "$COMPUTER_NAME" ]; then
    log_var_error COMPUTER_NAME $chroot_env
    exit 1
fi

if [ -z "$ROOT_PASSWD" ]; then
    log_var_error ROOT_PASSWD $chroot_env
    exit 1
fi

if [ -z "$USER_NAME" ]; then
    log_var_error USER_NAME $chroot_env
    exit 1
fi

if [ -z "$USER_PASSWD" ]; then
    log_var_error USER_PASSWD $chroot_env
    exit 1
fi
