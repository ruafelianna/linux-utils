PUBLIC_KEY=''
OUT_DIR=''

if [ -z "$PUBLIC_KEY" ]; then
    log "Error: PUBLIC_KEY var is not defined in env.sh"
    exit 1
fi

if [ -z "$OUT_DIR" ]; then
    log "Error: OUT_DIR var is not defined in env.sh"
    exit 1
fi
