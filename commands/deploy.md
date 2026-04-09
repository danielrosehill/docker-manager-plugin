---
description: Deploy a new Docker Compose stack or manage an existing one.
allowed-tools:
  - Bash
  - Read
  - Write
---

# Stack Deployment Assistant

Help the user deploy or manage Docker Compose stacks.

## Initial Questions

1. Ask the user what they want to deploy:
   - A new stack from scratch
   - An existing stack from the `stacks/` directory
   - A stack from a remote repository

2. Ask where to store the compose files:
   - In this repository under `stacks/{stack-name}/`
   - In a separate repository
   - In a custom location

## For New Stacks

1. Gather requirements:
   - What service(s) are needed?
   - What ports should be exposed?
   - What volumes are needed?
   - Environment variables required?
   - Network configuration?

2. Generate the compose file with:
   - Proper service definitions
   - Health checks where appropriate
   - Restart policies
   - Resource limits if specified
   - Proper volume mounts

3. Create a README.md for the stack explaining:
   - Purpose of the stack
   - Required configuration
   - How to start/stop
   - Exposed ports
   - Volume locations

## For Existing Stacks

1. Validate the compose file: `docker compose -f {file} config`
2. Show what will be created/modified
3. Deploy with: `docker compose -f {file} up -d`
4. Verify deployment: `docker compose -f {file} ps`

## After Deployment

- Update `context/environments/{env}.md` with new container info
- Log the deployment in the context folder
