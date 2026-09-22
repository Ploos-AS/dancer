# Upstream compatibility boundary

Ploos-AS/dancer packages the pinned upstream Dancer 4.16 release. It is not a feature fork.

## Pinned upstream

- Release: Dancer 4.16
- Source: SourceForge release archive pinned in `Dockerfile`
- SHA-256: `b61d754811a8cdb0ee0eb3ea50bae5d257f7eb070d5a94febfe7ba11728c1dca`

The archive checksum and upstream GPL license are verified during the image build.

## Allowed source changes

Upstream source changes are allowed only when required to build or operate the unchanged Dancer 4.16 feature set on supported modern platforms. Every source change must be explicit in `Dockerfile`, documented here, and covered by CI.

Current compatibility changes:

1. `list.h`: remove legacy `##` token-pasting syntax rejected by modern preprocessors.
2. `netstuff.c` and `netstuff.h`: change `inline void WriteSocket` to an ordinary external function for modern compiler inline/link semantics.
3. `netstuff.c`: use `send(2)` for IRC socket output and emit CRLF framing, preserving intended IRC wire behavior.

The build also uses `-std=gnu89`, `-Wno-error=implicit-function-declaration`, and `-lm`. These are build compatibility settings, not source-feature changes.

## No-fork rule

Do not add IRC bot features, commands, protocol extensions, configuration features, or behavior changes to the upstream Dancer source tree.

Modern operational features belong outside upstream source: entrypoint tooling, configuration tooling, CI fixtures, observability/exporters, transport sidecars, and deployment definitions.

If a future upstream source modification is unavoidable, update this inventory in the same change. CI checks the compatibility-edit surface so an unreviewed source-edit command cannot silently expand it.
