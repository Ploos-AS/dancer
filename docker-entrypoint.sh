#!/bin/sh
set -eu

config=${DANCER_CONFIG:-/data/dancer.config}
fail(){ echo "dancer-entrypoint: $*" >&2; exit 64; }

[ -f "$config" ] || fail "missing configuration: $config"
[ -r "$config" ] || fail "configuration is not readable: $config"

# Optional runtime-only secret overlays. Each variable names a readable file;
# its content is exported for external wrapper/tooling without modifying the
# pinned upstream Dancer source or persisting the secret into /data.
load_secret() {
  var=$1
  file_var=$2
  eval "secret_file=\${$file_var:-}"
  [ -z "$secret_file" ] && return 0
  [ -f "$secret_file" ] || fail "missing secret file for $file_var: $secret_file"
  [ -r "$secret_file" ] || fail "secret file is not readable for $file_var: $secret_file"
  secret_value=$(cat "$secret_file")
  export "$var=$secret_value"
}

load_secret DANCER_SERVER_PASSWORD DANCER_SERVER_PASSWORD_FILE
load_secret DANCER_OPER_PASSWORD DANCER_OPER_PASSWORD_FILE

exec /usr/local/bin/dancer "$@"
