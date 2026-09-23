#!/bin/sh
set -eu

# Base profile must remain usable without any secret file.
DANCER_URL=https://example.invalid/dancer.tar.gz DANCER_SHA256=0000000000000000000000000000000000000000000000000000000000000000 docker compose -f compose.yaml config >/tmp/dancer-compose-base.yaml

if grep -q 'dancer_config_overlay' /tmp/dancer-compose-base.yaml; then
  echo "Base Compose profile unexpectedly requires config overlay secret" >&2
  exit 1
fi

work=${RUNNER_TEMP:-/tmp}/dancer-compose-secret-$$
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work"
printf 'example=value\n' > "$work/overlay"

DANCER_URL=https://example.invalid/dancer.tar.gz DANCER_SHA256=0000000000000000000000000000000000000000000000000000000000000000 DANCER_CONFIG_OVERLAY_SOURCE="$work/overlay" docker compose -f compose.yaml -f compose.secrets.yaml config >/tmp/dancer-compose-secrets.yaml

grep -q 'DANCER_CONFIG_OVERLAY_FILE: /run/secrets/dancer_config_overlay' /tmp/dancer-compose-secrets.yaml
grep -q 'dancer_config_overlay' /tmp/dancer-compose-secrets.yaml
grep -Fq "$work/overlay" /tmp/dancer-compose-secrets.yaml

echo "Base and opt-in Compose secrets profiles qualified"
