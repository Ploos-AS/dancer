#!/bin/sh
set -eu

work=${RUNNER_TEMP:-/tmp}/dancer-config-validate-$$
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work"

cid=$(docker create dancer:config-ci)
docker cp "$cid:/usr/local/share/dancer/dancer.config" "$work/reference.conf"
docker rm "$cid" >/dev/null

DANCER_CONFIG_REFERENCE="$work/reference.conf" tools/dancer-config-validate "$work/reference.conf"

cp "$work/reference.conf" "$work/unknown.conf"
printf '\nDANCER_CI_UNKNOWN_DIRECTIVE=value\n' >> "$work/unknown.conf"
if DANCER_CONFIG_REFERENCE="$work/reference.conf" tools/dancer-config-validate "$work/unknown.conf"; then
  echo "Unknown directive unexpectedly accepted" >&2
  exit 1
fi

cp "$work/reference.conf" "$work/crlf.conf"
printf '\r\n' >> "$work/crlf.conf"
if DANCER_CONFIG_REFERENCE="$work/reference.conf" tools/dancer-config-validate "$work/crlf.conf"; then
  echo "CR contamination unexpectedly accepted" >&2
  exit 1
fi

echo "Config validator qualified against pinned upstream example and negative mutations"
