# Dancer TLS Compose profile

This profile keeps upstream Dancer 4.16 unchanged and terminates the outbound TLS transport in a separate stunnel container.

## Configure

1. Copy your Dancer runtime files into `deploy/tls/config/`.
2. Set Dancer's IRC server to `tls-proxy:6667`.
3. Set `IRC_TLS_HOST` to the remote IRC server hostname.
4. Optionally set `IRC_TLS_PORT` (default: 6697) and `DANCER_IMAGE`.
5. Start with `docker compose up -d`.

Example environment:

```sh
IRC_TLS_HOST=irc.example.net
IRC_TLS_PORT=6697
DANCER_IMAGE=ghcr.io/ploos-as/dancer:0.2
```

Do not publish port 6667. The `dancer-internal` network is marked internal and is the only network Dancer joins. Only the TLS proxy joins the outbound network.

The stunnel configuration requires CA-chain and hostname verification and sends SNI for `IRC_TLS_HOST`. A certificate validation failure prevents the remote IRC connection.

## Security boundary

Dancer itself has no direct outbound network in this profile. It can only reach the TLS proxy over the private Compose network. Both services drop Linux capabilities, enable `no-new-privileges`, and use read-only root filesystems with explicit tmpfs paths.

The proxy image is intentionally a simple reference profile. Production deployments may pin a dedicated stunnel image by digest, but must preserve the verification requirements in `docs/TLS.md`.
