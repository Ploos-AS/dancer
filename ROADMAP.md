# Roadmap

## M0 — OCI bootstrap

- [x] Establish Alpine-first / Debian-fallback policy.
- [x] Add non-root multi-stage OCI skeleton.
- [x] Add Compose security baseline.
- [x] Add CI structure validation.
- [x] Identify canonical Dancer 4.16 SourceForge release.
- [x] Pin canonical source URL and SHA-256.
- [x] Record upstream project license as GPLv2; archive-level verification remains before redistribution.
- [x] Carry forward the known gnu89 build requirement.
- [x] Qualify native amd64 build on Alpine/musl in GitHub Actions.
- [x] Confirm executable/configuration runtime semantics: Dancer loads `dancer.config` from `/data` and remains running after startup.
- [x] Qualify deterministic non-root UID/GID 10001:10001 and writable `/data`.
- [x] Qualify Compose security/runtime contract: read-only rootfs, no-new-privileges, all capabilities dropped, init, restart policy, /data bind mount, and /tmp tmpfs.
- [ ] Qualify isolated local IRC registration/handshake in CI.
- [x] Qualify amd64 and arm64 in CI.
- [ ] Publish first GHCR image only after qualification.

## M1

- Harden runtime and health checking.
- Add SBOM/provenance generation.
- Evaluate arm/v7 and 386.
- Extend IRC integration coverage beyond registration (PING/PONG, join/channel behavior, reconnect).
