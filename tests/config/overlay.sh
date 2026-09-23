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


# End-to-end container startup with overlay enabled. Use the exact upstream line
# as the replacement so semantics remain unchanged while the runtime path is exercised.
printf '%s\n' "$line" > "$work/container-overlay"
mkdir -p "$work/runtime"
cp "$work/dancer.config" "$work/runtime/dancer.config"
sudo chown -R 10001:10001 "$work/runtime"
status=0
docker run --name dancer-overlay-e2e \
  -v "$work/runtime:/data:ro" \
  -v "$work/container-overlay:/run/secrets/dancer-config-line:ro" \
  -e DANCER_CONFIG_OVERLAY_FILE=/run/secrets/dancer-config-line \
  dancer:config-ci >/tmp/dancer-overlay-e2e.log 2>&1 || status=$?
docker cp dancer-overlay-e2e:/tmp/dancer.config "$work/generated-container.conf"
docker rm dancer-overlay-e2e >/dev/null
cmp "$work/dancer.config" "$work/generated-container.conf"
mode=$(stat -c '%a' "$work/generated-container.conf")
case "$mode" in
  600|400) ;;
  *) echo "Container-generated config has unsafe mode: $mode" >&2; exit 1 ;;
esac
# Dancer may exit cleanly when the example config cannot reach its sample IRC
# endpoint; this test qualifies overlay generation and entrypoint handoff.
[ "$status" -eq 0 ] || {
  cat /tmp/dancer-overlay-e2e.log >&2
  exit "$status"
}
echo "Container entrypoint overlay path qualified"
