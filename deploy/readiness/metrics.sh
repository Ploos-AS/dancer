#!/bin/sh
set -eu

out=${DANCER_METRICS_FILE:-/metrics/dancer.prom}
interval=${DANCER_METRICS_INTERVAL:-15}
case "$interval" in ''|*[!0-9]*) echo "invalid metrics interval" >&2; exit 64 ;; esac

mkdir -p "$(dirname "$out")"
while :; do
  tmp="${out}.$$"
  dancer-metrics > "$tmp"
  chmod 0644 "$tmp"
  mv -f "$tmp" "$out"
  sleep "$interval"
done
