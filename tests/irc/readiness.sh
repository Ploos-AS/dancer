#!/bin/sh
set -eu

container=${1:-dancer-m0-test-client}
irc_container=${2:-irc-test}
max_age=${DANCER_READY_MAX_AGE:-120}

docker inspect "$container" >/dev/null 2>&1 || exit 1
[ "$(docker inspect "$container" --format '{{.State.Running}}')" = true ] || exit 1

logs=$(docker logs --since "${max_age}s" "$irc_container" 2>&1 || true)
printf '%s\n' "$logs" | grep -q 'DANCER_IRC_HANDSHAKE_OK'
printf '%s\n' "$logs" | grep -q 'DANCER_IRC_PING_PONG_OK'
printf '%s\n' "$logs" | grep -q 'DANCER_IRC_CHANNEL_OK'
