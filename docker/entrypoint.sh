#!/bin/bash
set -euo pipefail

BIND_ADDRESS="${BIND_ADDRESS:-0.0.0.0:80}"
DB_URL="${DB_URL:-sqlite:///db.sqlite}"
INSTANCE_NAME="${INSTANCE_NAME:-default}"
DOMAIN="${DOMAIN:-modoboa.local}"
ADMIN_BIN="/usr/local/bin/modoboa-admin.py"
WORK_DIR="/app"

CMD="$ADMIN_BIN deploy $INSTANCE_NAME --dburl default:$DB_URL --domain $DOMAIN"

#if [ "$1" == gunicorn ]; then
#    /bin/sh -c "flask db upgrade"
#    exec "$@" $GUNICORN_ARGS
#
#else
#    exec "$@"
#fi
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
if [ ! -d "$INSTANCE_NAME" ]; then
    echo "$INSTANCE_NAME does not exist"
    echo "Creating it"
    echo "$CMD"
    exec $CMD
fi
#exec "$ADMIN_BIN deploy $APP_ARGS"
