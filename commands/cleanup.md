---
description: Analyze unused Docker resources and guide the user through safe cleanup options.
allowed-tools:
  - Bash
---

# Docker Cleanup Assistant

Help the user safely clean up unused Docker resources.

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
