#!/bin/sh
set -eu

target=${1:?usage: qualify.sh <ergo|inspircd|solanum>}
image=${DANCER_IMAGE:-dancer:ircd-matrix}
network="dancer-${target}-ci"
server="${target}-ci"
client="dancer-${target}"
config_dir="tests/ircd-${target}"

case "$target" in
  ergo)
    server_image=${IRCD_IMAGE:-ghcr.io/ergochat/ergo:stable}
    ;;
  inspircd)
    server_image=${IRCD_IMAGE:-inspircd/inspircd-docker:4.8.0}
    ;;
  solanum)
    server_image=${IRCD_IMAGE:-solanum:dancer-ci}
    ;;
  *)
    echo "unsupported IRCd target: $target" >&2
    exit 64
    ;;
esac

cleanup() {
  docker rm -f "$client" "$server" >/dev/null 2>&1 || true
  docker network rm "$network" >/dev/null 2>&1 || true
  rm -rf "$config_dir"
}
trap cleanup EXIT HUP INT TERM

docker network create "$network" >/dev/null
mkdir -p "$config_dir"
cid=$(docker create "$image")
docker cp "$cid:/usr/local/share/dancer/." "$config_dir/"
docker rm "$cid" >/dev/null

awk -v server="$server" 'BEGIN{done=0} !done && $0 ~ /^[[:space:]]*#?[[:space:]]*server[[:space:]]*=/ { $0="server = " server ":6667"; done=1 } {print}' "$config_dir/dancer.config" > "$config_dir/dancer.config.new"
mv "$config_dir/dancer.config.new" "$config_dir/dancer.config"
sed -i -E 's|^[[:space:]]*#?[[:space:]]*channel[[:space:]]*=.*$|channel = #dancer-ci|' "$config_dir/dancer.config"
sed -i -E 's|^[[:space:]]*#?[[:space:]]*nick[[:space:]]*=.*$|nick = dancer-ci|' "$config_dir/dancer.config"
sudo chown -R 10001:10001 "$config_dir"

case "$target" in
  inspircd)
    docker run -d --name "$server" --network "$network" -e INSP_ENABLE_DNSBL=no "$server_image" >/dev/null
    ;;
  *)
    docker run -d --name "$server" --network "$network" "$server_image" >/dev/null
    ;;
esac

for _ in $(seq 1 30); do
  if docker run --rm --network "$network" alpine:3.22 sh -c "nc -z $server 6667"; then break; fi
  sleep 1
done
docker run --rm --network "$network" alpine:3.22 sh -c "nc -z $server 6667"

docker run -d --name "$client" --network "$network" -v "$PWD/$config_dir:/data" "$image" >/dev/null
registered=0
joined=0
for _ in $(seq 1 30); do
  if docker exec "$client" sh -c 'grep -Eiq "(001|Welcome)" /data/logfile /data/dancer.serv 2>/dev/null'; then registered=1; fi
  if docker exec "$client" sh -c 'grep -Eiq "(JOIN|joined|#dancer-ci)" /data/logfile /data/dancer.serv 2>/dev/null'; then joined=1; fi
  [ "$registered" -eq 1 ] && [ "$joined" -eq 1 ] && break
  sleep 1
done

echo "=== $target IRCd logs ==="
docker logs "$server" || true
echo "=== Dancer logs ==="
docker logs "$client" || true
echo "=== Dancer runtime files ==="
for x in "$config_dir/logfile" "$config_dir/dancer.serv"; do
  [ ! -f "$x" ] || { echo "--- $x"; cat "$x"; }
done

test "$(docker inspect "$client" --format '{{.State.Running}}')" = true
test "$registered" -eq 1
test "$joined" -eq 1
echo "Dancer registration and channel behavior qualified against $target"
