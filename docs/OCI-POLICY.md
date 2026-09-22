# Ploos-AS OCI base image policy

## Rule

**Alpine first — Debian when necessary.**

New OCI projects qualify Alpine/musl first. Debian slim/glibc is the fallback
when Alpine creates concrete compatibility, dependency, upstream, maintenance,
or disproportionate patching problems.

Image size is not allowed to override reliability or maintainability.

## Dancer M0

Dancer is therefore tested on Alpine first. If qualification fails for a
substantive musl/upstream reason, the failure and rationale must be documented
before switching the primary image to Debian slim.
