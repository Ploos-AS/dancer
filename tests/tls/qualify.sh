#!/bin/sh
set -eu

work=${RUNNER_TEMP:-/tmp}/dancer-tls-$$
network=dancer-tls-ci
cleanup() {
  docker rm -f dancer-tls-proxy dancer-tls-server >/dev/null 2>&1 || true
  docker network rm "$network" >/dev/null 2>&1 || true
  rm -rf "$work"
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
if printf 'SHOULD_FAIL\r\n' | docker run --rm -i --network "$network" alpine:3.22 nc -w 3 dancer-tls-proxy 6667 >/dev/null 2>&1; then
  echo "hostname-mismatched TLS connection unexpectedly succeeded" >&2
  docker logs dancer-tls-proxy >&2 || true
  exit 1
fi

echo "External TLS proxy trust and hostname verification qualified"
