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
- [ ] Confirm executable/configuration runtime semantics.
- [ ] Add real IRC startup/smoke test.
- [x] Qualify amd64 and arm64 in CI.
- [ ] Publish first GHCR image only after qualification.

## M1

- Harden runtime and health checking.
- Add SBOM/provenance generation.
- Evaluate arm/v7 and 386.
- Add IRC integration test against a disposable test IRC server.
