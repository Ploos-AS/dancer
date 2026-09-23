# TLS transport strategy

Dancer 4.16 is treated as an unchanged IRC application. TLS is therefore provided outside Dancer rather than by adding TLS feature code to the upstream source.

## Architecture

```text
Dancer 4.16 -> plaintext loopback/private container network -> TLS proxy -> IRC server:6697
```

The plaintext leg MUST remain local to the host or isolated container network. It MUST NOT be published on an untrusted network.

## Reference transport

The M3 reference implementation uses `stunnel` as a small external TLS client proxy. Dancer connects to the proxy on TCP/6667; the proxy establishes and verifies TLS to the configured IRC endpoint.

Required properties:

- TLS peer certificate verification is enabled.
- The system CA trust store is used unless an explicitly managed CA bundle is supplied.
- SNI is sent for the configured IRC hostname.
- Certificate/hostname verification failure is fatal.
- The local plaintext listener is not exposed outside the deployment boundary.
- Credentials remain in Dancer configuration/secrets handling; the TLS proxy does not add Dancer feature semantics.
- Dancer upstream source is not modified for TLS.

## Container profile

A deployment should use a dedicated proxy container sharing only an isolated network with Dancer. Dancer's `server` setting points at the proxy service, not directly at the remote TLS IRC server.

The proxy is independently restartable and observable. This preserves the no-fork boundary and allows the TLS implementation to be upgraded without rebuilding or modifying Dancer.

## Qualification contract

CI qualification for the TLS profile must prove:

1. Dancer reaches an IRC endpoint through the proxy.
2. the remote leg is TLS;
3. a trusted certificate succeeds;
4. an untrusted or hostname-mismatched certificate fails;
5. the plaintext listener is scoped to the isolated test network;
6. Dancer still performs the normal registration/PING/JOIN contract through the transport.

Until those checks pass in CI, TLS remains implemented as an architecture/profile rather than M3-qualified.
