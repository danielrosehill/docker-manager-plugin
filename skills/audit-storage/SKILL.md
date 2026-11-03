---
name: audit-storage
description: Audit container storage on a Docker host - which running containers have persistent storage and which don't (state that would be lost on recreate), where each bind mount and named volume actually lives on disk, which sit outside the user's common volume root, anonymous volumes, orphaned volumes, and sizes. Read-only. Use for "which containers have persistent storage", "where are my docker volumes", "are my volumes in the right place", "what would I lose if I recreate this container".
---

# Audit storage

Procedure: `shared/running-on-hosts.md`. Sections: `containers disk`.

## Classify each container's mounts

From `mounts` (type, name, source, dest, rw) and `declared_volumes` (the image's
`VOLUME` paths):

- **bind** → host path = `source`.
- **volume, named** → host path = `source` (normally `/var/lib/docker/volumes/<name>/_data`).
- **volume, anonymous** (64-hex name) → data survives a restart but is orphaned the
  next time the container is recreated (compose `up` after an image update, Watchtower
  included). Flag: effectively not persistent.
- **tmpfs** → not persistent.
- Config-only binds (`*.conf`, `/etc/localtime`, `/var/run/docker.sock`, `/dev/*`,
  read-only file mounts) don't count as persistent data.

## Checks

1. **No persistent storage.** A running container with no data mount at all.
   Many are fine stateless (nginx, MCP shims, proxies), so split them:
   - image declares a `VOLUME` that isn't mounted, or is a known stateful image
     (postgres, mariadb, mysql, mongo, redis with persistence, qdrant, minio, n8n,
     jellyfin config, …) → **flag: state will be lost**.
   - otherwise → list as "stateless, confirm".
2. **Outside the volume root.** Every persistent source not under one of
   `volume_roots` (and not in `volume_root_exceptions`) → flag. Docker-managed named
   volumes under `/var/lib/docker/volumes` count as outside unless that path is a root.
   Group findings by the directory they're in, so a pattern (e.g. everything under
   `/root/…`) is one line, not ten.
3. **Orphans.** Dangling volume count from `disk`; with the user's yes, list them with
   sizes (`docker volume ls -f dangling=true`, then `du -sh` on each mountpoint with
   sudo). Never remove; that's `/cleanup`, one volume at a time.
4. **Sizes** of the biggest data directories, only if asked or if the disk is above
   80 % (`du` on a large tree is slow).

## Output

Three short lists per host: **at risk** (no persistence on a stateful service,
anonymous volumes), **misplaced** (outside the root), **stateless** (confirm). Then a
tally: `52 containers: 30 bind, 8 named, 2 anonymous, 12 none`. A move is a plan only
(stop, copy with `rsync -aHAX`, repoint the compose file, start, verify), never done
without a yes.
