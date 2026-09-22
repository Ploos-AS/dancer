# Roadmap

## M0 — OCI bootstrap

- [x] Establish Alpine-first / Debian-fallback policy.
- [x] Add non-root multi-stage OCI skeleton.
- [x] Add Compose security baseline.
- [x] Add CI structure validation.
- [x] Identify canonical Dancer 4.16 SourceForge release.
- [x] Pin canonical source URL and SHA-256.
- [x] Verify the pinned Dancer 4.16 archive contains its GNU GPL license (`COPYING`) during every build.
- [x] Carry forward the known gnu89 build requirement.
- [x] Qualify native amd64 build on Alpine/musl in GitHub Actions.
- [x] Confirm executable/configuration runtime semantics: Dancer loads `dancer.config` from `/data` and remains running after startup.
- [x] Qualify deterministic non-root UID/GID 10001:10001 and writable `/data`.
- [x] Qualify Compose security/runtime contract: read-only rootfs, no-new-privileges, all capabilities dropped, init, restart policy, /data bind mount, and /tmp tmpfs.
- [x] Qualify isolated local IRC registration/handshake in CI.
- [x] Qualify amd64 and arm64 in CI.
- [x] Publish first qualified GHCR image (`v0.1.0`) for amd64 and arm64 with SBOM, provenance, and attestation.

## M1

- [x] Harden runtime and health checking: native Dancer PID healthcheck qualified in CI.
- [x] Add SBOM/provenance generation and registry attestation (delivered with `v0.1.0`).
- [x] Qualify arm/v7 and 386 builds in CI alongside amd64 and arm64.
- [x] Extend IRC integration coverage beyond registration: PING/PONG, join/channel behavior, and container-level reconnect/recovery.
