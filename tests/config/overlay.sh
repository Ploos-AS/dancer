#!/bin/sh
set -eu

work=${RUNNER_TEMP:-/tmp}/dancer-overlay-$$
cleanup() { rm -rf "$work"; }
trap cleanup EXIT HUP INT TERM
mkdir -p "$work"

cid=$(docker create dancer:config-ci)
docker cp "$cid:/usr/local/share/dancer/dancer.config" "$work/dancer.config"
docker rm "$cid" >/dev/null

# Select a real, unmodified upstream config line containing ':' or '='.
line=$(grep -m1 -E '^[^#[:space:]].*[:=]' "$work/dancer.config" || true)
[ -n "$line" ] || {
  echo "No overlay-safe line found in pinned upstream dancer.config" >&2
  exit 1
}
case "$line" in
  *:*) key=${line%%:*}: ;;
  *=*) key=${line%%=*}= ;;
esac
matches=$(grep -F -c "$key" "$work/dancer.config" || true)
[ "$matches" -eq 1 ] || {
  echo "Selected upstream key is not unique: $key ($matches matches)" >&2
  exit 1
}

# Change only the value while preserving the upstream delimiter/prefix.
case "$line" in
  *:*) replacement="${key} DANCER_CI_OVERLAY_VALUE" ;;
  *=*) replacement="${key} DANCER_CI_OVERLAY_VALUE" ;;
esac
printf '%s\n' "$replacement" > "$work/secret-line"

out=$(DANCER_CONFIG_OVERLAY_FILE="$work/secret-line" tools/dancer-config-overlay "$work/dancer.config" "$work/generated.conf")
[ "$out" = "$work/generated.conf" ]
[ "$(grep -F -c "$replacement" "$work/generated.conf")" -eq 1 ]
[ "$(grep -F -c "$line" "$work/generated.conf")" -eq 0 ]
[ "$(wc -l < "$work/generated.conf")" -eq "$(wc -l < "$work/dancer.config")" ]

# Secret output must not be group/world-readable.
mode=$(stat -c '%a' "$work/generated.conf")
case "$mode" in
  600|400) ;;
  *) echo "Generated config has unsafe mode: $mode" >&2; exit 1 ;;
esac

# Refuse unknown keys instead of silently inventing Dancer semantics.
printf 'DANCER_CI_UNKNOWN_KEY=secret\n' > "$work/unknown"
if DANCER_CONFIG_OVERLAY_FILE="$work/unknown" tools/dancer-config-overlay "$work/dancer.config" "$work/should-not-exist.conf"; then
  echo "Unknown overlay key unexpectedly accepted" >&2
  exit 1
fi

echo "Syntax-preserving config overlay qualified against pinned upstream dancer.config"
