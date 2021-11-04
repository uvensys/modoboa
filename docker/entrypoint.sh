#!/bin/bash
set -euo pipefail

ADMIN_BIN="/usr/local/bin/modoboa-admin.py"
WORK_DIR="/app"
DB_URL="${DB_URL:-sqlite:///db.sqlite}"
INSTANCE_NAME="${INSTANCE_NAME:-default}"
DOMAIN="${DOMAIN:-modoboa.local}"
GUNICORN_TIMEOUT="${GUNICORN_TIMEOUT:-120}"
GUNICORN_WORKERS="${GUNICORN_WORKERS:-4}"
GUNICORN_LOGLEVEL="${GUNICORN_LOGLEVEL:-info}"
BIND_ADDRESS="${BIND_ADDRESS:-0.0.0.0:80}"

GUNICORN_ARGS="-t ${GUNICORN_TIMEOUT} --workers ${GUNICORN_WORKERS} --bind ${BIND_ADDRESS} --log-level ${GUNICORN_LOGLEVEL} $INSTANCE_NAME.wsgi:application"
CREATE_CMD="$ADMIN_BIN deploy $INSTANCE_NAME --dburl default:$DB_URL --domain $DOMAIN"

if [ "$1" == gunicorn ]; then
    #/bin/sh -c "flask db upgrade"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    if [ ! -d "$INSTANCE_NAME" ]; then
        echo "$INSTANCE_NAME does not exist"
        echo "Creating it"
        echo "$CREATE_CMD"
        exec $CREATE_CMD
    fi
    echo "$@" $GUNICORN_ARGS
    #exec "$@" $GUNICORN_ARGS
    cd /app/default
    gunicorn default.wsgi:application

else
    exec "$@"
fi
