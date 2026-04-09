---
description: Refresh workspace context files with the current Docker environment state.
allowed-tools:
  - Bash
  - Read
  - Write
---

# Update Environment Context

Refresh the context files with current Docker environment state.

## Tasks

1. **Probe Current State**:
   - `docker ps -a` - All containers
   - `docker images` - All images
   - `docker network ls` - All networks
   - `docker volume ls` - All volumes
   - `docker system df` - Disk usage

2. **Read Existing Context**: Check `context/environments/` for the environment file

3. **Generate Updated Context**: Update the environment file with:
   - Current date/time of update
   - Container inventory (name, image, status, ports)
   - Image catalog with sizes
   - Network topology
   - Volume list with sizes
   - Resource usage summary

4. **Diff Report**: Show what changed since last update:
   - New containers
   - Removed containers
   - Status changes
   - New images/volumes

5. **Save Changes**: Write updated context files

## Output

Provide a summary of changes detected since last context update.
