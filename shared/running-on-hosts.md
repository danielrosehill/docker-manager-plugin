# Running the audit on a host

Every audit skill gathers its facts with `scripts/docker-audit.sh` (read-only) and
judges them against the user's preferences. This file is the shared procedure.

## 1. Load preferences

```bash
P=$("${CLAUDE_PLUGIN_ROOT}/scripts/paths.sh" prefs)
```

Read the YAML block in `$P`, and the **Notes** bullets: they override the YAML where
they conflict. If `paths.sh` returned the shipped example, say so once in the report
("no preferences recorded; judged against defaults") and offer the `preferences` skill.

## 2. Pick hosts

The user named a host → that one. Otherwise every entry in `hosts:`. Skip any
container matching `ignore_containers` (shell-glob match on the name, without the leading `/`).

## 3. Run the script, by transport

| transport | how |
| --- | --- |
| `local` | `bash "${CLAUDE_PLUGIN_ROOT}/scripts/docker-audit.sh" <sections>` |
| `ssh` | `ssh <target> 'bash -s' -- <sections> < "${CLAUDE_PLUGIN_ROOT}/scripts/docker-audit.sh"` |
| `tool` | the tool runs a command string on the host, so ship the script inline: `gzip -9c docker-audit.sh \| base64 -w0` locally, then send `echo '<b64>' \| base64 -d \| gunzip > /tmp/docker-audit.sh && bash /tmp/docker-audit.sh <sections>`. Later calls in the same session can reuse `/tmp/docker-audit.sh`. |

Sections: `host engine containers watchtower autostart disk`. Ask only for what the
skill needs. `containers` prints one JSON object per container. On a host with many
containers, write it to a file on the host and query it with `jq` there rather than
pulling every line back. `disk` runs `docker system df`, which can take a minute or
more on a busy host (it sizes every volume), and has its own 150 s timeout.

Use a tool timeout of at least 180 s. If the daemon does not answer, every docker
call times out after 30 s (`DOCKER_AUDIT_TIMEOUT`); report the daemon as unresponsive
and stop, rather than reading empty output as "no containers".

## 4. Report

Lead with findings, worst first, one line each: `host · container · what's wrong · what
the preference says`. Then a one-line count of what passed. No raw dumps. Mark each
finding **confirmed** (seen in output) or **inferred**. These skills only read; any fix
is a suggestion with the exact command, and runs only on the user's yes.
