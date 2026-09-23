#!/bin/sh
set -eu

work=${RUNNER_TEMP:-/tmp}/dancer-observer-$$
network=dancer-observer-$$
cleanup() {
  docker rm -f dancer-observer-fixture dancer-observer-bridge >/dev/null 2>&1 || true
  rm -rf "$work"
  docker network rm "$network" >/dev/null 2>&1 || true
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$work/bin" "$work/state"

docker network create "$network" >/dev/null
docker run -d --name dancer-observer-fixture --network "$network"   -v "$PWD/tests/irc:/irc:ro" python:3.13-alpine   python /irc/server.py >/dev/null

ln -s "$PWD/tools/dancer-readiness-mark" "$work/bin/dancer-readiness-mark"
PATH="$work/bin:$PATH"
export PATH

# Feed observer events through the production watcher.
mkfifo "$work/events"
DANCER_READY_STATE_FILE="$work/state/ready"   tools/dancer-readiness-watch < "$work/events" &
watch_pid=$!

# Observer must prove a real IRC registration/join against the fixture.
DANCER_OBSERVER_HOST=127.0.0.1 DANCER_OBSERVER_PORT=16667 DANCER_OBSERVER_CHANNEL='#dancer-ci' DANCER_OBSERVER_INTERVAL=2   tools/dancer-irc-observer > "$work/events" 2>"$work/observer.log" &
observer_pid=$!

# Bridge host port into the isolated fixture network without exposing Dancer.
docker run -d --name dancer-observer-bridge --network "$network"   -p 127.0.0.1:16667:16667 alpine:3.22 sh -c   "apk add --no-cache socat >/dev/null && exec socat TCP-LISTEN:16667,fork,reuseaddr TCP:dancer-observer-fixture:6667" >/dev/null

ok=0
i=0
while [ "$i" -lt 20 ]; do
  if DANCER_READY_STATE_FILE="$work/state/ready" DANCER_READY_MAX_AGE=30 tools/dancer-readiness; then
    ok=1
    break
  fi
  i=$((i + 1))
  sleep 1
done
[ "$ok" -eq 1 ] || {
  cat "$work/observer.log" >&2 || true
  docker logs dancer-observer-fixture >&2 || true
  exit 1
}

kill "$observer_pid" >/dev/null 2>&1 || true
kill "$watch_pid" >/dev/null 2>&1 || true
wait "$observer_pid" 2>/dev/null || true
wait "$watch_pid" 2>/dev/null || true

echo "External IRC readiness observer qualified"
