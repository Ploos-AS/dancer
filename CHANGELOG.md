# Changelog

All notable packaging, runtime, qualification, and release changes to this
repository are documented here.

The project packages upstream Dancer 4.16; repository release versions describe
the OCI packaging and operational contract rather than a new upstream Dancer
version.

## Unreleased

### Added
- CI qualification against Ergo, InspIRCd, and Solanum.
- External TLS transport qualification including CA trust, hostname verification,
  IRC registration, PING/PONG, channel join, and reconnect recovery.
- Readiness observer and Prometheus deployment qualification.

### Changed
- GitHub Actions used by CI and release publishing updated to current Node 24-compatible major releases.
- Release gate now explicitly requires pinned upstream checksum, GPL license marker,
  and documented compatibility-edit verification.
- Architecture documentation aligned with the qualified amd64, arm64, arm/v7,
  and 386 release matrix.

## v0.2.0 — 2026-09-23

### Added
- Four-architecture release target: amd64, arm64, arm/v7, and 386.
- Published-image manifest and amd64 metadata smoke tests.
- Configuration preflight requiring a readable `/data/dancer.config`.
- Operations documentation for backup, restore, upgrade, rollback, and
  container-level IRC recovery.
- Weekly Dependabot coverage for Docker and GitHub Actions dependencies.

## v0.1.0

- First qualified GHCR release for amd64 and arm64.
- Alpine/musl multi-stage build of pinned upstream Dancer 4.16.
- Non-root UID/GID 10001 runtime and hardened Compose contract.
- SBOM, provenance, and registry attestation.
- Qualified local IRC registration handshake.
