---
description: Perform a comprehensive health check of all Docker containers and resources.
allowed-tools:
  - Bash
---

# Docker Environment Status Check

Perform a comprehensive health check of the Docker environment.

## Tasks

1. **Container Status**: Run `docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"` and analyze:
   - Which containers are running vs stopped
   - Any containers in unhealthy or restarting state
   - Uptime of running containers

2. **Resource Usage**: Run `docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"` to show current resource consumption

3. **Disk Usage**: Run `docker system df` to show:
   - Image space usage
   - Container space usage
   - Volume space usage
   - Build cache usage

4. **Recent Events**: Run `docker events --since 1h --until now 2>/dev/null | tail -20` to check for recent issues

5. **Health Summary**: Provide a brief summary including:
   - Total containers (running/stopped/total)
   - Any containers that need attention
   - Disk space warnings if usage is high
   - Recommendations if any issues found

## Output Format

Present a concise status report. Flag any issues or warnings prominently.
