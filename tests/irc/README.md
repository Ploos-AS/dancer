# IRC integration test fixture

This directory contains the M0 Dancer IRC integration fixture.

The CI test is completely isolated from public IRC networks:

- a dedicated Docker network is created;
- `server.py` provides a disposable local IRC endpoint on that network;
- Dancer receives a test-only copy of the pinned upstream example configuration;
- the server target is rewritten to `irc-test[:6667]`;
- CI requires both `NICK` and `USER` registration commands and a successful local handshake marker;
- the client, endpoint, and network are removed after the test.

The fixture never connects to the upstream example server list and must not
contain production IRC credentials.

M1 may extend this fixture with protocol behavior such as PING/PONG,
channel/join behavior, and reconnect qualification.
