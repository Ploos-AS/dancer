# Dancer OCI

OCI packaging for the legacy **Dancer IRC bot**.

> This repository packages upstream Dancer. It is not the upstream Dancer project.

## M0

- Alpine-first build following Ploos-AS OCI policy.
- Debian slim only as a documented fallback when Alpine/musl is impractical.
- Non-root runtime.
- External configuration under `/data`.
- Docker/Podman Compose example.
- CI build, startup/shutdown, Compose-contract, and isolated IRC registration smoke tests.
- Qualified multi-arch builds for amd64 and arm64.
- Upstream source and license qualification before a release is published.

## Base image policy

**Alpine first — Debian when necessary.** We do not force Alpine when musl compatibility, dependencies, upstream assumptions, maintenance cost, or disproportionate patching make Debian slim the better technical choice.

## Build

```sh
docker build -t dancer:local .
```

## Configuration

Mount operator configuration at `/data` (the image's working directory and Compose bind-mount target). Secrets must not be baked into the image. See `config/README.md`.

## Compose

Copy `.env.example` to `.env`, add the qualified Dancer configuration, then use:

```sh
docker compose up -d
```

## Security

The runtime is unprivileged and contains no compiler toolchain. The Compose example drops Linux capabilities and enables `no-new-privileges`.

## Architectures

M0 CI validates the native build. Release publishing is prepared for `linux/amd64` and `linux/arm64`; arm/v7 and 386 can be added after qualification.

## Upstream

Dancer project site: https://dancer.sourceforge.net/

## License

Dancer retains its upstream license. M0 must verify the license from the exact upstream source archive before redistribution/release publication. Packaging-specific files follow the applicable Ploos-AS software policy.
