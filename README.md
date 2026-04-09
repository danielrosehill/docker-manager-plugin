# Docker Manager Plugin

A Claude Code plugin providing slash commands and subagents for managing Docker containers, Compose stacks, volumes, networks, and multi-environment deployments.

## What it does

This plugin turns Claude Code into a capable Docker administration assistant. It ships slash commands for day-to-day operations and specialized subagents for deeper analysis tasks. A context directory pattern lets Claude maintain an up-to-date picture of your Docker environments across sessions.

## Commands

| Command | Description |
|---------|-------------|
| `/setup` | Probe the local system, run a guided intake interview, and generate initial context files |
| `/status` | Comprehensive health check — containers, resource usage, disk, recent events |
| `/cleanup` | Analyze unused resources and guide through safe removal options |
| `/logs [container]` | View and analyze logs for a specific container |
| `/deploy` | Deploy a new Compose stack or manage an existing one |
| `/backup` | Backup Docker volumes to a local directory or remote destination |
| `/update-context` | Refresh context files to reflect the current environment state |

## Agents

| Agent | Use case |
|-------|----------|
| `container-diagnostics` | Debug crashes, restart loops, and connectivity failures |
| `compose-generator` | Generate production-ready Compose files with supporting docs |
| `security-audit` | Audit for security misconfigurations with a prioritised report |
| `migration-planner` | Plan and execute container migrations between environments |
| `resource-optimizer` | Analyse CPU, memory, and storage usage and recommend optimisations |

## Installation

```bash
claude plugin install danielrosehill/docker-manager-plugin
```

Or add to your project's `.claude/plugin.json` manifest.

## Getting started

1. Open Claude Code in the directory where you want to manage Docker.
2. Run `/setup` — Claude will probe your system, ask a few configuration questions, and write initial context files.
3. Use `/status` to verify everything looks healthy.
4. Run any slash command or invoke an agent as needed.

## Context management

After running `/setup`, a `context/` directory holds environment profiles, network topology notes, volume inventory, and backup logs. Keep this up to date with `/update-context` after significant changes. The `.gitignore` excludes `context/` by default since it may contain host-specific data; override this if you want to version-control it.

## Multi-environment support

The workspace can manage multiple Docker environments:

- **Local** — the Docker installation on your current machine.
- **Remote** — Docker hosts reachable via SSH. Document each in `context/environments/{hostname}.md`.

## Security notes

- Never commit `.env` files containing real secrets.
- Review the `security-audit` agent output periodically.
- Use environment variables or a secrets manager for credentials.

## License

MIT License. See [LICENSE](LICENSE).
