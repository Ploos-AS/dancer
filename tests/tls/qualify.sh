#!/bin/sh
set -eu

work=${RUNNER_TEMP:-/tmp}/dancer-tls-$$
network=dancer-tls-ci
cleanup() {
  docker rm -f dancer-tls-client dancer-tls-proxy dancer-tls-server >/dev/null 2>&1 || true
  docker network rm "$network" >/dev/null 2>&1 || true
  sudo rm -rf "$work"
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$work"
docker network create "$network" >/dev/null

# Create an isolated CA and a server certificate valid only for irc-tls-ci.
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj '/CN=Dancer CI CA' -keyout "$work/ca.key" -out "$work/ca.crt" >/dev/null 2>&1
openssl req -newkey rsa:2048 -nodes -subj '/CN=irc-tls-ci' -keyout "$work/server.key" -out "$work/server.csr" >/dev/null 2>&1
printf 'subjectAltName=DNS:irc-tls-ci\n' > "$work/ext"
openssl x509 -req -days 1 -in "$work/server.csr" -CA "$work/ca.crt" -CAkey "$work/ca.key" -CAcreateserial -extfile "$work/ext" -out "$work/server.crt" >/dev/null 2>&1

# TLS endpoint; it only needs to prove a verified encrypted transport.
docker run -d --name dancer-tls-server --network "$network" --network-alias irc-tls-ci \
  -v "$work:/tls:ro" alpine:3.22 sh -c \
  "apk add --no-cache openssl >/dev/null && openssl s_server -accept 6697 -cert /tls/server.crt -key /tls/server.key -quiet" >/dev/null

cat > "$work/stunnel.conf" <<'EOF'
foreground = yes
client = yes
[dancer-irc]
accept = 0.0.0.0:6667
connect = irc-tls-ci:6697
verifyChain = yes
checkHost = irc-tls-ci
CAfile = /tls/ca.crt
sni = irc-tls-ci
EOF

docker run -d --name dancer-tls-proxy --network "$network" \
  -v "$work:/tls:ro" alpine:3.22 sh -c \
  "apk add --no-cache stunnel ca-certificates >/dev/null && stunnel /tls/stunnel.conf" >/dev/null

for _ in $(seq 1 30); do
  if docker run --rm --network "$network" alpine:3.22 sh -c 'nc -z dancer-tls-proxy 6667'; then break; fi
  sleep 1
done
docker run --rm --network "$network" alpine:3.22 sh -c 'nc -z dancer-tls-proxy 6667'

# Trusted CA + matching hostname must pass through the proxy.
printf 'DANCER_TLS_OK\r\n' | docker run --rm -i --network "$network" alpine:3.22 nc dancer-tls-proxy 6667 >/dev/null

# A hostname mismatch must prevent the proxy from establishing the remote TLS leg.
sed 's/checkHost = irc-tls-ci/checkHost = wrong.invalid/' "$work/stunnel.conf" > "$work/stunnel-bad.conf"
docker rm -f dancer-tls-proxy >/dev/null
docker run -d --name dancer-tls-proxy --network "$network" \
  -v "$work:/tls:ro" alpine:3.22 sh -c \
  "apk add --no-cache stunnel ca-certificates >/dev/null && stunnel /tls/stunnel-bad.conf" >/dev/null
sleep 2
printf 'SHOULD_FAIL\r\n' | docker run --rm -i --network "$network" alpine:3.22 nc -w 3 dancer-tls-proxy 6667 >/dev/null 2>&1 || true
sleep 1
bad_logs=$(docker logs dancer-tls-proxy 2>&1 || true)
if ! printf '%s\n' "$bad_logs" | grep -Eq 'Subject checks failed|Rejected by CERT|certificate verify failed'; then
  echo "hostname-mismatched TLS connection was not rejected by certificate verification" >&2
  printf '%s\n' "$bad_logs" >&2
  exit 1
fi

echo "External TLS proxy trust and hostname verification qualified"


# Full Dancer IRC protocol qualification through the verified TLS proxy.
docker rm -f dancer-tls-client dancer-tls-proxy dancer-tls-server >/dev/null 2>&1 || true
docker run -d --name dancer-tls-server --network "$network" --network-alias irc-tls-ci \
  -v "$work:/tls:ro" -v "$PWD/tests/irc:/irc:ro" alpine:3.22 sh -c \
  "apk add --no-cache openssl socat python3 >/dev/null && socat OPENSSL-LISTEN:6697,reuseaddr,cert=/tls/server.crt,key=/tls/server.key,verify=0 EXEC:'python3 /irc/server.py'" >/dev/null
docker run -d --name dancer-tls-proxy --network "$network" \
  -v "$work:/tls:ro" alpine:3.22 sh -c \
  "apk add --no-cache stunnel ca-certificates >/dev/null && stunnel /tls/stunnel.conf" >/dev/null

config_dir="$work/dancer"
mkdir -p "$config_dir"
cid=$(docker create dancer:tls-ci)
docker cp "$cid:/usr/local/share/dancer/." "$config_dir/"
docker rm "$cid" >/dev/null
awk 'BEGIN{done=0} !done && $0 ~ /^[[:space:]]*#?[[:space:]]*server[[:space:]]*=/ { $0="server = dancer-tls-proxy:6667"; done=1 } {print}' "$config_dir/dancer.config" > "$config_dir/dancer.config.new"
mv "$config_dir/dancer.config.new" "$config_dir/dancer.config"
sed -i -E 's|^[[:space:]]*#?[[:space:]]*channel[[:space:]]*=.*$|channel = #dancer-ci|' "$config_dir/dancer.config"
sed -i -E 's|^[[:space:]]*#?[[:space:]]*nick[[:space:]]*=.*$|nick = dancer-ci|' "$config_dir/dancer.config"
sudo chown -R 10001:10001 "$config_dir"

docker run -d --name dancer-tls-client --restart unless-stopped --network "$network" \
  -v "$config_dir:/data" \
  -e DANCER_CONFIG_REFERENCE=/data/dancer.config \
  dancer:tls-ci >/dev/null
for _ in $(seq 1 45); do
  logs=$(docker logs dancer-tls-server 2>&1 || true)
  printf '%s\n' "$logs" | grep -q 'DANCER_IRC_RECONNECT_OK' && break
  sleep 1
done
logs=$(docker logs dancer-tls-server 2>&1 || true)
printf '%s\n' "$logs"
if ! printf '%s\n' "$logs" | grep -q 'DANCER_IRC_RECONNECT_OK'; then
  echo "TLS protocol qualification timed out" >&2
  echo "=== TLS proxy logs ===" >&2
  docker logs dancer-tls-proxy >&2 || true
  echo "=== Dancer logs ===" >&2
  docker logs dancer-tls-client >&2 || true
  echo "=== Dancer runtime logfile ===" >&2
  cat "$config_dir/logfile" >&2 2>/dev/null || true
  exit 1
fi
printf '%s\n' "$logs" | grep -q 'DANCER_IRC_HANDSHAKE_OK'
printf '%s\n' "$logs" | grep -q 'DANCER_IRC_PING_PONG_OK'
printf '%s\n' "$logs" | grep -q 'DANCER_IRC_CHANNEL_OK'
printf '%s\n' "$logs" | grep -q 'DANCER_IRC_RECONNECT_OK'
echo "Dancer registration, PING/PONG, JOIN, and recovery qualified through TLS proxy"
