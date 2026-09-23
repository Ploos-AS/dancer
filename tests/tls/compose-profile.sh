#!/bin/sh
set -eu

compose=deploy/tls/compose.yaml
test -f "$compose"

docker compose -f "$compose" config >/tmp/dancer-tls-compose.yaml

# Dancer must only join the private internal network.
awk '
  /^  dancer:$/ { in_dancer=1; next }
  in_dancer && /^  [a-zA-Z0-9_-]+:$/ { in_dancer=0 }
  in_dancer { print }
' /tmp/dancer-tls-compose.yaml > /tmp/dancer-tls-service.yaml
grep -q 'dancer-internal' /tmp/dancer-tls-service.yaml
if grep -q 'outbound' /tmp/dancer-tls-service.yaml; then
  echo "Dancer unexpectedly has direct outbound network access" >&2
  exit 1
fi

# The proxy is the only bridge between the internal and outbound networks.
awk '
  /^  tls-proxy:$/ { in_proxy=1; next }
  in_proxy && /^  [a-zA-Z0-9_-]+:$/ { in_proxy=0 }
  in_proxy { print }
' /tmp/dancer-tls-compose.yaml > /tmp/dancer-tls-proxy.yaml
grep -q 'dancer-internal' /tmp/dancer-tls-proxy.yaml
grep -q 'outbound' /tmp/dancer-tls-proxy.yaml

# The private network must remain internal and no plaintext port may be published.
grep -A4 '^  dancer-internal:' /tmp/dancer-tls-compose.yaml | grep -q 'internal: true'
if grep -Eq 'published: "?6667"?|^- "?6667:' /tmp/dancer-tls-compose.yaml; then
  echo "plaintext IRC port 6667 is published" >&2
  exit 1
fi

grep -q 'no-new-privileges:true' /tmp/dancer-tls-compose.yaml
grep -q 'cap_drop:' /tmp/dancer-tls-compose.yaml
grep -q 'read_only: true' /tmp/dancer-tls-compose.yaml

echo "TLS Compose network isolation and hardening policy qualified"
