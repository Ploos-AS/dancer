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


## Optional secret-backed config overlay

The base `compose.yaml` does not require secrets and preserves the normal upstream Dancer configuration path.

For a secret value that must not be stored in Git, place one complete replacement configuration line in a host file and start Compose with the opt-in override:

```sh
DANCER_CONFIG_OVERLAY_SOURCE=/secure/path/dancer-config-line \\
  docker compose -f compose.yaml -f compose.secrets.yaml up -d
```

The secret file is mounted as `/run/secrets/dancer_config_overlay`. The entrypoint copies the normal `dancer.config` through the syntax-preserving overlay helper and writes the generated configuration to runtime-only storage before starting Dancer.

The overlay deliberately does not understand or invent Dancer directives. Its secret file must contain one complete `:` or `=` configuration line whose prefix already occurs exactly once in the pinned upstream-derived configuration. Unknown or ambiguous prefixes are rejected.

Keep the source secret outside the repository. Do not add `secrets/` contents to version control.


## External configuration tools

The image includes three deliberately conservative tools:

- `dancer-config-generate` starts from the pinned upstream Dancer 4.16 example and optionally applies complete-line overlays.
- `dancer-config-overlay` replaces only an existing, uniquely matched `:` or `=` line prefix.
- `dancer-config-validate` compares directive prefixes with the pinned upstream example and rejects unknown structure before Dancer starts.

Generate an unchanged operator copy from the image reference configuration:

```sh
docker run --rm --entrypoint dancer-config-generate \\
  -v "$PWD/config:/out" \\
  ghcr.io/ploos-as/dancer:0.2 /out/dancer.config
```

For overlays, mount each overlay file and provide their paths in `DANCER_CONFIG_OVERLAYS`, separated by colons. Each overlay file contains one complete replacement configuration line. The generator validates the resulting file before writing it.

These tools are not a replacement parser for Dancer 4.16. They intentionally derive their structural contract from the pinned upstream example so that modern operational tooling does not become a feature fork or an undocumented configuration dialect.
