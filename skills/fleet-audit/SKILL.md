---
name: fleet-audit
description: Full read-only audit of one or all Docker hosts in the user's preferences - host load and memory, containers running/unhealthy/restarting, engine version and pending updates, Watchtower status and history, autostart and restart policies, persistent storage and volume locations, deployment sources, and reclaimable disk space - in one report saved to the user's data dir. Use for "audit my docker hosts", "check docker everywhere", "docker health check on the server and laptop", "full docker report".
---

# Fleet audit

Runs every audit in one pass per host and writes one report. Procedure:
`shared/running-on-hosts.md`.

1. Load preferences and pick hosts (all in `hosts:` unless the user named one).
2. Per host, run the script once with all sections, saving container JSON on the host
   (`... containers > /tmp/docker-audit.containers.jsonl`). Hosts are independent:
   run them in parallel.
3. Judge with the rules in these skills, without re-running the script:
   `audit-engine`, `audit-watchtower`, `audit-autostart`, `audit-storage`,
   `audit-deployments`. Plus:
   - **Load:** loadavg ÷ nproc above 1 for the 15-min figure, available memory under
     10 %, swap nearly full → flag.
   - **Containers:** `unhealthy`, `restarting`, high `restart_count`, `exited` with a
     non-zero code that has a restart policy → flag. (`docker stats --no-stream` only
     if load is flagged; it's slow on big hosts.)
   - **Disk:** reclaimable images and build cache from `docker system df`, dangling
     image and volume counts, docker root filesystem usage above 80 % → flag; point at
     `/cleanup` for the fix.
4. Write the report to `$(scripts/paths.sh dir)/reports/YYYY-MM-DD_<host>.md`. If one
   for today exists, add `-2`, `-3`; never overwrite. Commit just that file if the data
   dir is in a git repo.
5. Reply with the headline per host (worst three findings) and the report path. The
   report has the full findings, each tagged confirmed/inferred, and a "suggested
   fixes" list with exact commands, none of them run.
