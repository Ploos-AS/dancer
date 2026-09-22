# Operations

Dancer keeps its operator-managed configuration and runtime state under `/data`.
With the supplied Compose file this is the host directory `./config`.

## Backup

Stop the service before taking a consistent backup:

```sh
docker compose stop dancer
tar -C . -czf "dancer-data-$(date +%Y%m%d-%H%M%S).tar.gz" config
docker compose start dancer
```

Keep backups outside the repository and protect them as secrets: `dancer.config`
and related files may contain IRC credentials.

## Restore

Stop Dancer, preserve the current directory, restore the selected archive, fix
ownership, then start and inspect health/logs:

```sh
docker compose stop dancer
mv config "config.before-restore-$(date +%Y%m%d-%H%M%S)"
tar -C . -xzf dancer-data-YYYYMMDD-HHMMSS.tar.gz
sudo chown -R 10001:10001 config
docker compose up -d dancer
docker compose ps dancer
docker compose logs --tail=100 dancer
```

## Upgrade

Back up `./config` first. Pin `DANCER_IMAGE` in `.env` to the intended
version instead of relying on a moving tag, then pull and recreate:

```sh
docker compose pull dancer
docker compose up -d dancer
docker compose ps dancer
docker compose logs --tail=100 dancer
```

The container entrypoint refuses to start when `/data/dancer.config` is absent
or unreadable.

## Rollback

Set `DANCER_IMAGE` back to the previously qualified version and recreate the
service:

```sh
docker compose pull dancer
docker compose up -d --force-recreate dancer
```

If an upgrade changed runtime data incompatibly, restore the backup made before
the upgrade as described above.

## Disconnect recovery

Dancer 4.16 exits cleanly when its IRC connection reaches EOF rather than
reconnecting in the same process. The supplied Compose configuration therefore
uses `restart: unless-stopped`. CI qualifies recovery at the container level:
Dancer exits after a forced IRC disconnect, Docker restarts it, and the new
process must register, answer PING/PONG, and join the configured channel again.
