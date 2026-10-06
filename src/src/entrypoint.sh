#!/bin/sh
set -e

: "${TRUSTED_PROXY_CIDR:=172.16.0.0/12}"
export TRUSTED_PROXY_CIDR

envsubst '${TRUSTED_PROXY_CIDR}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

if [ ! -f /etc/nginx/.htpasswd ]; then
    if [ -n "$WEBDAV_USER" ] && [ -n "$WEBDAV_PASSWORD" ]; then
        htpasswd -cb /etc/nginx/.htpasswd "$WEBDAV_USER" "$WEBDAV_PASSWORD"
        echo "[entrypoint] Created /etc/nginx/.htpasswd for user '$WEBDAV_USER'"
    else
        echo "[entrypoint] ERROR: /etc/nginx/.htpasswd not found and WEBDAV_USER/WEBDAV_PASSWORD are not set." >&2
        echo "[entrypoint] Either mount a ready-made .htpasswd at /etc/nginx/.htpasswd," >&2
        echo "[entrypoint] or set the WEBDAV_USER and WEBDAV_PASSWORD environment variables." >&2
        exit 1
    fi
fi

nginx -t

exec "$@"
