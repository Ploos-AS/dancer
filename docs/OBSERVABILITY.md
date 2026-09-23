# Readiness and observability

Dancer 4.16 is not modified to add monitoring features. M3 observes the packaged bot externally and keeps operational state outside the upstream source tree.

## Liveness versus readiness

The OCI healthcheck is a process-liveness check: PID 1 must be the Dancer process. It does not claim that IRC registration or channel membership works.

Connection readiness is a separate external contract. An IRC observer emits qualified events, `tools/dancer-readiness-watch` records those observations, and `tools/dancer-readiness` accepts the service only while the last successful IRC observation is fresh.

`DANCER_READY_STATE_FILE` selects the readiness timestamp file and defaults to `/run/dancer/ready`. `DANCER_READY_MAX_AGE` defaults to 120 seconds.

## Observer state

The watcher keeps these files next to the readiness timestamp:

- `ready`: Unix timestamp of the latest qualified channel-ready observation.
- `channel_up`: `1` after a channel-ready event and `0` after a disconnect event.
- `reconnects`: successful reconnect observations since watcher startup.
- `observer_started_at`: Unix timestamp when the watcher started.

This state describes what the external observer has verified. It is deliberately not presented as internal Dancer instrumentation.

## Prometheus metrics

`tools/dancer-metrics` renders the state in Prometheus text exposition format:

- `dancer_irc_ready` — 1 when the latest qualified IRC observation is within the configured freshness window, otherwise 0.
- `dancer_irc_observation_age_seconds` — age of the latest observation; -1 when no usable observation exists.
- `dancer_irc_channel_up` — external observer's current channel state.
- `dancer_irc_reconnects_total` — successful reconnect observations since the watcher started.
- `dancer_observer_uptime_seconds` — uptime of the external state watcher, not the upstream Dancer process.

The metric generator is intentionally a command-line text exporter. A deployment may expose its output through a sidecar/textfile collector without granting that component write access to Dancer configuration or modifying Dancer itself.

## Trust boundary

The readiness and metric values are only as authoritative as the observer that produces the event stream. CI uses the isolated IRC fixture to qualify the contract. Production deployment profiles must provide an observer with the same semantics before using these values for orchestration or alerting.


## Deployment profile

The reference readiness deployment now includes a dedicated `metrics` sidecar. It reads `/run/dancer` state read-only and periodically writes Prometheus text exposition to a separate `dancer-metrics` volume as `dancer.prom`.

This separation is intentional: the metrics process cannot create or alter readiness evidence. Only the observer/watcher owns readiness state. Metrics are derived from that state.

The textfile output is suitable for collection by a Prometheus Node Exporter textfile collector or another component that consumes Prometheus text exposition. The Dancer container itself does not expose an HTTP metrics endpoint and upstream Dancer 4.16 remains unchanged.

CI qualifies both the metric values from representative observer state and the Compose read/write boundaries.
