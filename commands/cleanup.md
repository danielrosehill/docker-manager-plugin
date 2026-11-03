---
description: Analyze unused Docker resources and guide the user through safe cleanup options.
allowed-tools:
  - Bash
---

# Docker Cleanup Assistant

Help the user safely clean up unused Docker resources.

**Preferences and hosts.** Read the `cleanup:` block and `hosts:` from the preferences file
(`${CLAUDE_PLUGIN_ROOT}/scripts/paths.sh prefs`) and honour them: with
`never_prune_volumes: true` never run `docker volume prune` or `docker system prune
--volumes`, only remove volumes one at a time on an explicit yes; don't prune unused images
younger than `min_image_age_hours` (`docker image prune -a --filter until=<N>h`); keep build
cache if `keep_build_cache`. For a remote host, run the commands through its transport
(`shared/running-on-hosts.md`). Before removing a volume, check the `audit-storage` rules:
a dangling named volume can still be the only copy of a stack's data.

## Analysis Phase

First, analyze what can be cleaned:

1. **Stopped Containers**: Run `docker ps -a -f status=exited --format "{{.Names}}\t{{.Image}}\t{{.Status}}"`
2. **Dangling Images**: Run `docker images -f dangling=true -q | wc -l`
3. **Unused Images**: Run `docker images --format "{{.Repository}}:{{.Tag}}\t{{.Size}}" | head -20`
4. **Unused Volumes**: Run `docker volume ls -f dangling=true`
5. **Unused Networks**: Run `docker network ls -f dangling=true`
6. **Build Cache**: Run `docker builder prune --dry-run 2>/dev/null || echo "Build cache info unavailable"`

Show the user:
- How many stopped containers exist
- How much space dangling images consume
- Orphaned volumes and networks

## Cleanup Options

Present cleanup options to the user:

1. **Safe Cleanup** (recommended): Remove only dangling/unused resources
   - `docker container prune`
   - `docker image prune`
   - `docker volume prune` (with confirmation)
   - `docker network prune`

2. **Deep Cleanup**: Remove all unused resources
   - `docker system prune -a`

3. **Selective Cleanup**: Let user choose specific resources to remove

## Important

- Always confirm before removing volumes (data loss risk)
- Never remove running containers without explicit confirmation
- Show space savings after cleanup
