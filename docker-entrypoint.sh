#!/bin/sh
set -eu

config=${DANCER_CONFIG:-/data/dancer.config}
fail(){ echo "dancer-entrypoint: $*" >&2; exit 64; }

[ -f "$config" ] || fail "missing configuration: $config"
[ -r "$config" ] || fail "configuration is not readable: $config"

if [ -n "${DANCER_CONFIG_OVERLAY_FILE:-}" ]; then
  generated=${DANCER_GENERATED_CONFIG:-/tmp/dancer.config}
  dancer-config-overlay "$config" "$generated" >/dev/null
  config=$generated
  cd "$(dirname "$config")"
  # Dancer 4.16 resolves dancer.config from its working directory.
  [ "$(basename "$config")" = "dancer.config" ] || fail "generated config must be named dancer.config"
fi

dancer-config-validate "$config" >/dev/null || fail "configuration validation failed: $config"

exec /usr/local/bin/dancer "$@"
