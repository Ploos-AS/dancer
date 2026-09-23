# Connection-aware readiness

This profile keeps process health and IRC readiness separate.

- **Dancer health** answers whether the Dancer process is alive.
- **IRC readiness** answers whether an independent observer has recently proven IRC registration/channel reachability.
- **Observer loss or a known disconnect** fails readiness closed.

## Services

`dancer` runs the unchanged packaged Dancer 4.16 process.

`observer` runs a separate IRC client identity using `dancer-irc-observer`. Its events are piped to `dancer-readiness-watch`, which writes deployment-neutral state under `/run/dancer`.

`readiness` consumes that state read-only using `dancer-readiness`. It never inspects Dancer internals.

## Required settings

Set:

- `DANCER_OBSERVER_HOST`: IRC endpoint visible to the observer.
- `DANCER_OBSERVER_CHANNEL`: channel whose reachability should be proven.

Optional:

- `DANCER_OBSERVER_PORT` defaults to `6667`.
- `DANCER_OBSERVER_NICK` defaults to `dancer-observer`.
- `DANCER_OBSERVER_INTERVAL` defaults to 30 seconds.

The observer must use its own IRC identity. Do not reuse the bot nick.

For TLS deployments, point the observer at an appropriately secured endpoint or combine this profile with the documented TLS transport architecture. Do not expose a plaintext IRC listener merely to satisfy readiness.

## State contract

The observer/watcher owns write access to the shared state volume. Readiness consumers mount it read-only.

`ready` contains the Unix timestamp of the most recently proven ready event. `dancer-readiness` rejects missing, malformed, future, or stale timestamps. Disconnect and observer EOF remove the ready state.

Additional state files include `channel_up`, `reconnects`, and `observer_started_at`; these are also used by the external metrics tooling.

This is deliberately external to upstream Dancer. No readiness hooks or feature patches are added to Dancer 4.16.
