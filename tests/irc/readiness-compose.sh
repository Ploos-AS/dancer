#!/bin/sh
set -eu

DANCER_OBSERVER_HOST=irc.example.invalid DANCER_OBSERVER_CHANNEL='#dancer-ci' docker compose -f deploy/readiness/compose.yaml config >/tmp/dancer-readiness-compose.yaml

# All deployment roles must remain separate.
grep -q '^  dancer:' /tmp/dancer-readiness-compose.yaml
grep -q '^  observer:' /tmp/dancer-readiness-compose.yaml
grep -q '^  readiness:' /tmp/dancer-readiness-compose.yaml
grep -q '^  metrics:' /tmp/dancer-readiness-compose.yaml

# Observer owns write access to readiness state and runs the external pipeline.
grep -A40 '^  observer:' /tmp/dancer-readiness-compose.yaml > /tmp/dancer-observer-service.yaml
grep -q 'dancer-irc-observer | dancer-readiness-watch' /tmp/dancer-observer-service.yaml
grep -q 'target: /run/dancer' /tmp/dancer-observer-service.yaml
if grep -A4 'target: /run/dancer' /tmp/dancer-observer-service.yaml | grep -q 'read_only: true'; then
  echo "Observer state volume unexpectedly read-only" >&2
  exit 1
fi

# Readiness consumer may only read the shared state.
grep -A35 '^  readiness:' /tmp/dancer-readiness-compose.yaml > /tmp/dancer-readiness-service.yaml
grep -q 'dancer-readiness' /tmp/dancer-readiness-service.yaml
grep -A5 'target: /run/dancer' /tmp/dancer-readiness-service.yaml | grep -q 'read_only: true'

# Dancer never runs the observer pipeline itself.
grep -A35 '^  dancer:' /tmp/dancer-readiness-compose.yaml > /tmp/dancer-service.yaml
if grep -Eq 'dancer-irc-observer|dancer-readiness-watch' /tmp/dancer-service.yaml; then
  echo "Observer logic leaked into Dancer service" >&2
  exit 1
fi

echo "Readiness Compose role and state boundaries qualified"

# Metrics reads observer state read-only and writes only the dedicated metrics volume.
grep -A45 '^  metrics:' /tmp/dancer-readiness-compose.yaml > /tmp/dancer-metrics-service.yaml
grep -q 'target: /run/dancer' /tmp/dancer-metrics-service.yaml
grep -A5 'target: /run/dancer' /tmp/dancer-metrics-service.yaml | grep -q 'read_only: true'
grep -q 'target: /metrics' /tmp/dancer-metrics-service.yaml
