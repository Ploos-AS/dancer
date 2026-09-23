#!/bin/sh
set -eu

work=${RUNNER_TEMP:-/tmp}/dancer-metrics-$$
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/state" "$work/metrics"
now=$(date +%s)
printf '%s\n' "$now" > "$work/state/ready"
printf '1\n' > "$work/state/channel_up"
printf '3\n' > "$work/state/reconnects"
printf '%s\n' "$((now - 10))" > "$work/state/observer_started_at"

DANCER_READY_STATE_FILE="$work/state/ready" tools/dancer-metrics > "$work/direct.prom"
grep -q '^dancer_irc_ready 1$' "$work/direct.prom"
grep -q '^dancer_irc_channel_up 1$' "$work/direct.prom"
grep -q '^dancer_irc_reconnects_total 3$' "$work/direct.prom"
grep -Eq '^dancer_observer_uptime_seconds [0-9]+$' "$work/direct.prom"

PATH="$PWD/tools:$PATH" DANCER_READY_STATE_FILE="$work/state/ready" DANCER_METRICS_FILE="$work/metrics/dancer.prom" DANCER_METRICS_INTERVAL=1 timeout 3 deploy/readiness/metrics.sh || status=$?
status=${status:-0}
[ "$status" -eq 0 ] || [ "$status" -eq 124 ]
test -s "$work/metrics/dancer.prom"
grep -q '^# HELP dancer_irc_ready ' "$work/metrics/dancer.prom"
grep -q '^dancer_irc_ready 1$' "$work/metrics/dancer.prom"

echo "Prometheus textfile metrics deployment qualified"
