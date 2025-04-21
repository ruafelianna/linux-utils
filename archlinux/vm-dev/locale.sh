{
    echo $ECHO_START'Loading locale settings...' && \
    source $BASE_DIR/env-locale.sh
} && \

{
    echo $ECHO_START'Loading keys...' && \
    loadkeys $KEYMAP && \

    echo $ECHO_START'Setting font...' && \
    setfont $FONT
} && \

{
    for locale in "${LOCALES[@]}"
    do
        l="$locale.UTF-8 UTF-8" && \

        echo $ECHO_START'Uncommenting locale: '$l'...' && \
        sed -i "s/#$l/$l/" /etc/locale.gen
    done
} && \

{
    echo $ECHO_START'Generating locale...' && \
    locale-gen
} && \

{
    echo $ECHO_START'Setting language...' && \
    echo "LANG=$LOCALE.UTF-8" > /etc/locale.conf
} && \

{
    echo $ECHO_START'Setting console settings...' && \
    cat > /etc/vconsole.conf << EOF
KEYMAP=$KEYMAP
FONT=$FONT
EOF
}
