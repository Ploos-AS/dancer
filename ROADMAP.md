# Roadmap

## M0 — OCI bootstrap

- [x] Establish Alpine-first / Debian-fallback policy.
- [x] Add non-root multi-stage OCI skeleton.
- [x] Add Compose security baseline.
- [x] Add CI structure validation.
- [ ] Inspect canonical Dancer 4.16 source archive.
- [ ] Verify upstream license from archive.
- [ ] Pin canonical source URL and SHA-256.
- [ ] Qualify build on Alpine/musl.
- [ ] Confirm executable path and configuration semantics.
- [ ] Add real startup/smoke test.
- [ ] Qualify amd64 and arm64.
- [ ] Publish first GHCR image only after qualification.

## M1

- Harden runtime and health checking.
- Add SBOM/provenance generation.
- Evaluate arm/v7 and 386.
- Add IRC integration test against a disposable test IRC server.
