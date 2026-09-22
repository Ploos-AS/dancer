# Changelog

All notable packaging, runtime, qualification, and release changes to this
repository are documented here.

The project packages upstream Dancer 4.16; repository release versions describe
the OCI packaging and operational contract rather than a new upstream Dancer
version.

## Unreleased

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
