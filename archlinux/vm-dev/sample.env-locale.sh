LOCALE=ru_RU
LOCALES=(en_US $LOCALE)
KEYMAP=ru
FONT=ter-v32n
COUNTRY=Russia
TZ=Europe/Moscow

locale_env='env-locale.sh'

if [ -z "$LOCALE" ]; then
    log_var_error LOCALE $locale_env
    exit 1
fi

if [ -z "$LOCALES" ]; then
    log_var_error LOCALES $locale_env
    exit 1
fi

if [ -z "$KEYMAP" ]; then
    log_var_error KEYMAP $locale_env
    exit 1
fi

if [ -z "$FONT" ]; then
    log_var_error FONT $locale_env
    exit 1
fi

if [ -z "$COUNTRY" ]; then
    log_var_error COUNTRY $locale_env
    exit 1
fi

if [ -z "$TZ" ]; then
    log_var_error TZ $locale_env
    exit 1
fi
