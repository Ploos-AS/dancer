#!/bin/sh
set -eu

config=${DANCER_CONFIG:-/data/dancer.config}
fail(){ echo "dancer-entrypoint: $*" >&2; exit 64; }

[ -f "$config" ] || fail "missing configuration: $config"
[ -r "$config" ] || fail "configuration is not readable: $config"

exec /usr/local/bin/dancer "$@"
