# IRCd qualification matrix

M3 qualifies the packaged, unchanged Dancer 4.16 client behavior against modern IRC servers in isolated CI.

## Initial matrix

| IRCd | Container source | Plain IRC | TLS | Status |
| --- | --- | --- | --- | --- |
| Ergo | `ghcr.io/ergochat/ergo:stable` | 6667 | 6697 | CI target implemented; qualification pending green run |
| InspIRCd | `inspircd/inspircd-docker:4.8.0` | 6667 | 6697 | CI target implemented; qualification pending green run |
| Solanum | upstream-derived CI image | 6667 | external TLS strategy | CI target implemented; qualification pending green run |

Ergo and InspIRCd are first because their upstream projects document container operation and plaintext port 6667, which lets the compatibility test stay independent of the later TLS transport qualification.

## Required assertions

Each IRCd target must qualify the same observable Dancer contract:

1. TCP connection and IRC registration.
2. Dancer NICK and USER registration accepted by the server.
3. PING/PONG remains functional.
4. Dancer joins the configured test channel.
5. Disconnect behavior is recorded and container-level recovery remains consistent with the documented Dancer 4.16 semantics.

The test must not patch Dancer feature code for a specific IRCd. Server-specific setup belongs in the CI harness.

## TLS boundary

TLS is intentionally not part of the first plaintext compatibility gate. M3 has a separate secure-transport item so the project can qualify an external TLS proxy/sidecar without turning the Dancer packaging repository into a feature fork.
