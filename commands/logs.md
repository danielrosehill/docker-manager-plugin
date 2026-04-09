---
description: View and analyze logs for a Docker container.
argument-hint: "[container-name]"
allowed-tools:
  - Bash
---

# Container Logs Viewer

Help the user view and analyze container logs.

## Arguments

$ARGUMENTS

If the user provided a container name as an argument, use that directly.

## Tasks

1. **If no container specified**: List running containers with `docker ps --format "{{.Names}}\t{{.Image}}\t{{.Status}}"` and ask which one

2. **Fetch logs**: Use appropriate flags based on user needs:
   - Recent logs: `docker logs --tail 100 {container}`
   - Follow mode: `docker logs -f --tail 50 {container}`
   - With timestamps: `docker logs -t --tail 100 {container}`
   - Since time: `docker logs --since 1h {container}`

3. **Analysis**: After showing logs:
   - Identify any ERROR or WARNING patterns
   - Note any repeated error messages
   - Suggest potential issues if patterns detected
