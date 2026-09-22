# Dancer runtime directory

Dancer 4.16 resolves `dancer.config` relative to its current working directory.
The OCI image therefore uses `/data` as its working directory, and Compose mounts
the operator-managed `./config` directory there.

The runtime directory is expected to contain the upstream Dancer files:

- `dancer.config`
- `dancer.users`
- `dancer.funcs`
- `dancer.explain`

The image contains upstream example copies under `/usr/local/share/dancer/` and
also seeds `/data` when no external mount obscures it. For Compose operation,
copy/adapt the examples into this directory before starting the service.

Dancer may write runtime state in its working directory, so the `/data` mount is
intentionally writable even though the container root filesystem is read-only.

The image uses deterministic UID/GID `10001:10001` for the `dancer` account.
When using the Compose bind mount, ensure the host-side `./config` directory is
writable by that identity (or otherwise grants the required write access).

Do not commit passwords, IRC service credentials, or other secrets.
