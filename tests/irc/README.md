# IRC integration test fixture

This directory is reserved for the M0 Dancer IRC integration test.

The test must be completely isolated from public IRC networks:

- create a dedicated Docker network;
- run a disposable local IRC endpoint on that network;
- give Dancer a test-only `dancer.config`;
- verify that Dancer opens an IRC connection and performs registration;
- destroy the endpoint and network after the test.

Do not use the upstream example server list for integration testing and do not
store production IRC credentials here.

The exact Dancer 4.16 configuration directives will be taken from the pinned
upstream 4.16 source before the executable fixture is enabled.
