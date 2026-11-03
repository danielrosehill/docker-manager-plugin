---
name: audit-autostart
description: Audit what starts automatically on a Docker host - whether the Docker daemon is enabled at boot, each container's restart policy (no, always, unless-stopped, on-failure), systemd units or @reboot cron jobs that start containers outside Docker, and containers that would not come back after a reboot - against the user's recorded preferences. Read-only. Use for "what autostarts", "check restart policies", "will everything come back after a reboot", "which containers start on boot".
---

# Audit autostart

Procedure for running the script and reading preferences: `shared/running-on-hosts.md`.
Sections: `autostart containers`.

## Checks

1. **Daemon at boot.** `docker.service` enabled? If `autostart.daemon_enabled_at_boot`
   is true and it isn't, nothing comes back after a reboot: flag first. `docker.socket`
   enabled alone means the daemon starts on first use, not at boot: say so.
2. **Restart policy per container** (from `restart_policy`):
   - in `never_autostart` but policy isn't `no` → flag.
   - in `must_autostart` but policy not in `allowed_policies` → flag.
   - policy `no` (or empty) on a container that is **running** → it will not return
     after a reboot. Flag, unless it's in `never_autostart`.
   - policy not in `allowed_policies` (e.g. `always` when only `unless-stopped` is
     allowed) → flag as a mismatch with `default_policy`.
   - `always` vs `unless-stopped`: `always` restarts a container the user stopped by
     hand once the daemon restarts. Mention it only when the preference asks for
     `unless-stopped`.
   - `on-failure` with a high `restart_count` → crash loop, flag.
3. **Mixed policies inside one compose project** → flag; a stack usually wants one.
4. **Starts outside Docker.** Any systemd unit or `@reboot` cron that runs
   `docker compose up` / `docker start`: list them. They double-start containers that
   also have a restart policy, and they aren't visible from `docker ps`.
5. **Stopped containers with a restart policy** (`exited` + `always`/`unless-stopped`):
   with `always` they will start on the next daemon restart; with `unless-stopped` they
   won't. Note which, so nothing surprises the user after a reboot.

## Output

Findings per `shared/running-on-hosts.md`, then a policy tally (`53 unless-stopped,
14 always, 0 no`). A fix is `docker update --restart <policy> <name>`, but say that the
compose file must change too or the next `up` reverts it; give the file path from
`compose_files`. Nothing is changed without a yes.
