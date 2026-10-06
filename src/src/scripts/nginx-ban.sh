#!/bin/sh
set -e

FILE=/etc/nginx/conf.d/banned_ips.conf
LOCK=/tmp/nginx-ban.lock
ACTION="$1"
IP="$2"

if [ -z "$ACTION" ] || [ -z "$IP" ]; then
    echo "usage: $0 {add|del} <ip>" >&2
    exit 1
fi

exec 9>"$LOCK"
flock -w 10 9

case "$ACTION" in
    add)
        grep -qxF "deny $IP;" "$FILE" 2>/dev/null || echo "deny $IP;" >> "$FILE"
        ;;
    del)
        grep -vxF "deny $IP;" "$FILE" > "$FILE.tmp" 2>/dev/null || true
        mv "$FILE.tmp" "$FILE"
        ;;
    *)
        echo "unknown action: $ACTION" >&2
        exit 1
        ;;
esac

flock -u 9

nginx -t && nginx -s reload
