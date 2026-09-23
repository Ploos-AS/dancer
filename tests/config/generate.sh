#!/bin/sh
set -eu

work=${RUNNER_TEMP:-/tmp}/dancer-config-generate-$$
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/bin"

cid=$(docker create dancer:config-ci)
docker cp "$cid:/usr/local/share/dancer/dancer.config" "$work/reference.conf"
docker rm "$cid" >/dev/null

# Exercise repository tools directly while preserving the same command names
# used inside the runtime image.
ln -s "$PWD/tools/dancer-config-overlay" "$work/bin/dancer-config-overlay"
ln -s "$PWD/tools/dancer-config-validate" "$work/bin/dancer-config-validate"
PATH="$work/bin:$PATH"
export PATH

DANCER_CONFIG_REFERENCE="$work/reference.conf" tools/dancer-config-generate "$work/generated-a.conf"
DANCER_CONFIG_REFERENCE="$work/reference.conf" tools/dancer-config-generate "$work/generated-b.conf"
cmp "$work/reference.conf" "$work/generated-a.conf"
cmp "$work/generated-a.conf" "$work/generated-b.conf"

line=$(grep -m1 -E '^[[:space:]]*#[[:alnum:]_]+[[:space:]]*=' "$work/reference.conf" || true)
[ -n "$line" ] || { echo "No upstream template directive found" >&2; exit 1; }
key=$(printf '%s\n' "$line" | sed -n -E 's/^[[:space:]]*#([[:alnum:]_]+)[[:space:]]*=.*/\1/p')
replacement="$key = DANCER_CI_GENERATED_VALUE"
printf '%s\n' "$replacement" > "$work/overlay-1"

DANCER_CONFIG_REFERENCE="$work/reference.conf" DANCER_CONFIG_OVERLAYS="$work/overlay-1" tools/dancer-config-generate "$work/generated-overlay.conf"
[ "$(grep -F -c "$replacement" "$work/generated-overlay.conf")" -eq 1 ]

printf 'DANCER_CI_UNKNOWN_KEY=secret\n' > "$work/unknown"
if DANCER_CONFIG_REFERENCE="$work/reference.conf"    DANCER_CONFIG_OVERLAYS="$work/unknown"    tools/dancer-config-generate "$work/should-not-exist.conf"; then
  echo "Generator accepted unknown overlay key" >&2
  exit 1
fi

mode=$(stat -c '%a' "$work/generated-overlay.conf")
case "$mode" in
  600|400) ;;
  *) echo "Generated config has unsafe mode: $mode" >&2; exit 1 ;;
esac

echo "Reference-based config generator qualified"
