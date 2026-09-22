#!/bin/sh
set -eu
config=${DANCER_CONFIG:-/data/dancer.config}
fail(){ echo "dancer-entrypoint: $*" >&2; exit 64; }
[ -f "$config" ] || fail "missing configuration: $config"
[ -r "$config" ] || fail "configuration is not readable: $config"
for key in server channel nick; do
  grep -Eq "^[[:space:]]*${key}[[:space:]]*=[[:space:]]*[^#[:space:]].*" "$config" || fail "required directive '${key}' is missing or empty in $config"
done
exec /usr/local/bin/dancer "$@"
