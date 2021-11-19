#!/bin/bash
set -euo pipefail

ADMIN_BIN="/usr/local/bin/modoboa-admin.py"
WORK_DIR="/app"
DB_URL="${DB_URL:-sqlite:///db.sqlite}"
INSTANCE_NAME="${INSTANCE_NAME:-default}"
DOMAIN="${DOMAIN:-*}"
GUNICORN_TIMEOUT="${GUNICORN_TIMEOUT:-120}"
GUNICORN_WORKERS="${GUNICORN_WORKERS:-4}"
GUNICORN_LOGLEVEL="${GUNICORN_LOGLEVEL:-debug}"
#BIND_ADDRESS="${BIND_ADDRESS:-0.0.0.0:8080}"
BIND_ADDRESS="${BIND_ADDRESS:-unix:/run/gunicorn/modoboa.sock}"

GUNICORN_ARGS="-t ${GUNICORN_TIMEOUT} --workers ${GUNICORN_WORKERS} --bind ${BIND_ADDRESS} --log-level ${GUNICORN_LOGLEVEL} --log-config $INSTANCE_NAME/logging.conf $INSTANCE_NAME.wsgi:application"
CREATE_CMD="$ADMIN_BIN deploy ${INSTANCE_NAME} --collectstatic --dburl default:$DB_URL --domain $DOMAIN"

if [ "$1" == gunicorn ]; then
    #/bin/sh -c "flask db upgrade"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    if [ ! -d "$INSTANCE_NAME" ]; then
        echo "$INSTANCE_NAME does not exist"
        echo "Creating it"
        echo "$CREATE_CMD"
        exec $CREATE_CMD
	# copy logging conf
	cp /logging.conf "$WORK_DIR/$INSTANCE_NAME"
    fi
    echo "$@" $GUNICORN_ARGS
    cd "$WORK_DIR/$INSTANCE_NAME"
    exec "$@" $GUNICORN_ARGS
    #gunicorn default.wsgi:application

else
    exec "$@"
fi
