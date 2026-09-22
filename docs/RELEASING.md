# Release gate

A stable packaging release may be tagged only when all of the following are
true on `main`:

1. The full CI workflow is green.
2. Native Alpine runtime qualification passes.
3. Builds pass for amd64, arm64, arm/v7, and 386.
4. IRC integration passes registration, PING/PONG, channel join, and
   container-level disconnect recovery.
5. Configuration preflight tests pass.
6. Compose security/runtime contract tests pass.
7. `CHANGELOG.md` has no release-critical changes left only under
   `Unreleased`; the intended release notes are finalized.
8. The release workflow publishes all four architectures and its post-push
   GHCR manifest/image smoke tests pass.
9. SBOM, provenance, and registry attestation are produced by the release
   workflow.

A failed post-push release smoke test means the tag is not considered
qualified even if registry artifacts exist. Fix forward with a new version;
do not move or overwrite an existing release tag.
