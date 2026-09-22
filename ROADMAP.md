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

## M2 — Release hardening and operations

- [x] Publish the qualified four-architecture image (amd64, arm64, arm/v7, 386) in v0.2.0.
- [x] Add release smoke tests against the published GHCR manifest; v0.2.0 release workflow passed.
- [x] Document upgrades, rollback, backup, and restore for /data.
- [x] Add configuration validation/preflight before production startup: entrypoint requires a readable /data/dancer.config and CI qualifies the missing-config failure contract (exit 64).
- [x] Document Dancer 4.16 reconnect semantics and container restart recovery.
- [x] Add dependency/base-image update automation with CI qualification: weekly Dependabot updates are gated by the existing full PR CI.
- [x] Add release notes/changelog workflow and define the next stable release gate.


## M3 — Modern operations and IRC integration

**No-fork policy:** Ploos-AS/dancer packages upstream Dancer; it does not maintain a feature fork. Upstream source modifications are limited to minimal, documented compatibility fixes required to build or operate Dancer on supported platforms. New operational functionality belongs in external tooling, container integration, CI, or sidecars.

- [ ] Document and CI-enforce the no-fork boundary and inventory every upstream compatibility patch.
- [ ] Add secrets/config overlays without storing IRC credentials in Git.
- [ ] Add external configuration generation and syntax-aware validation based on documented upstream Dancer 4.16 semantics.
- [ ] Add connection-aware readiness distinct from the process healthcheck.
- [ ] Add external observability/Prometheus metrics for uptime, IRC connection state, reconnects, and channel state without modifying Dancer feature code.
- [ ] Qualify Dancer against a matrix of modern IRC daemons in isolated CI.
- [ ] Define and qualify a secure TLS transport strategy; prefer an external proxy/sidecar if native Dancer 4.16 TLS is insufficient.
- [ ] Add a tested configuration deployment/restart procedure.
- [ ] Add automated /data backup/restore verification.
- [ ] Add migration tooling for existing Dancer 4.16 installations.
- [ ] Document M3 deployment profiles suitable for Compose and LeanPi-style appliances.

### M3 release gate

M3 passes when upstream Dancer remains clearly identifiable and reproducible from the pinned 4.16 archive, all compatibility patches are minimal and documented, secrets can be deployed without Git, connection readiness and basic operational metrics are available externally, and the packaged bot is qualified against multiple modern IRCd implementations using the documented secure transport strategy.
