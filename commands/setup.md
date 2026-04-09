---
description: Probe the local Docker environment and generate initial context files for the workspace.
allowed-tools:
  - Bash
  - Read
  - Write
---

# Docker Manager Workspace Setup

Your task is to configure this workspace for the user's specific Docker environment.

## Setup Process

### Phase 1: Hardware & System Probe

Automatically gather the following information about the local host:

1. **Operating System**: Run `uname -a` and `cat /etc/os-release`
2. **CPU**: Run `lscpu | head -20`
3. **Memory**: Run `free -h`
4. **Storage**: Run `df -h /`
5. **Docker Version**: Run `docker --version` and `docker compose version`
6. **Docker Info**: Run `docker info 2>/dev/null | head -30`
7. **Current Containers**: Run `docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"`
8. **Current Images**: Run `docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"`
9. **Docker Networks**: Run `docker network ls`
10. **Docker Volumes**: Run `docker volume ls`

### Phase 2: User Intake Interview

After gathering system info, ask the user the following questions:

1. **Environment Name**: What should we call this environment? (e.g., "local", "homelab", "production-server")

2. **Scope**: Will you be managing:
   - Only this local Docker environment?
   - Multiple remote Docker environments via SSH?
   - Both local and remote?

3. **Remote Environments** (if applicable):
   - What are the hostnames or SSH aliases for remote Docker hosts?
   - Do you have SSH key authentication configured for these hosts?

4. **Stack Preferences**:
   - Do you want docker-compose stacks stored in this repository?
   - Or would you prefer separate repositories for each stack?

5. **Existing Infrastructure**:
   - Do you have existing compose stacks you would like to import into this workspace?
   - Are there specific containers or services you want documented?

6. **Backup & Monitoring**:
   - Do you have backup procedures for Docker volumes you want documented?
   - Are you using any monitoring tools (Portainer, Dozzle, etc.)?

### Phase 3: Context File Generation

Based on the gathered information, create the following files:

1. **`context/environments/{environment-name}.md`**: Detailed environment profile including:
   - Host specifications (OS, CPU, RAM, storage)
   - Docker version and configuration
   - Current container inventory
   - Network configuration

2. **`context/networks/overview.md`**: Docker network topology

3. **`context/volumes/overview.md`**: Volume inventory and purpose

4. **`context/images/inventory.md`**: Image catalog with sizes

### Phase 4: Finalization

1. Summarize what was configured
2. Suggest next steps (e.g., "You can now use /status to check container health")

## Output

Provide a summary of:
- Environment name and type
- Key statistics (containers, images, networks, volumes)
- Any issues or warnings detected
- Recommended next actions
