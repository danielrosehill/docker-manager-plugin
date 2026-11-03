---
name: audit-engine
description: Check whether the Docker Engine, containerd and the Compose plugin are up to date on a host - installed vs available package versions, install method (apt, snap, static, Docker Desktop), whether the apt repo matches the OS release, and daemon settings worth knowing (live-restore, log driver, log rotation). Read-only. Use for "is docker up to date", "check the docker engine version", "docker update available".
---

# Audit engine

Procedure: `shared/running-on-hosts.md`. Sections: `host engine`.

## Checks

1. **Version and method.** Report server, client and compose versions and how they
   were installed (`apt` lines, `snap docker`, `docker_cli_path` under
   `/usr/local/bin` usually means a static or Desktop install). Compare with
   `engine.install_method`. Client and server versions differing → flag.
2. **Pending updates (apt).** `installed` ≠ `candidate` for `docker-ce`,
   `containerd.io` or `docker-compose-plugin` → flag with both versions. A containerd
   update restarts every container: say so.
3. **Stale apt source.** `docker_apt_suite` codename ≠ `os_codename` (e.g. a `plucky`
   source on a `resolute` system), or `none` → the host gets no Engine updates even
   though apt reports nothing pending. Flag as a silent problem; "installed =
   candidate" proves nothing in that case.
4. **Latest upstream.** For non-apt installs or a stale source, compare with the latest
   Docker Engine release (`gh api repos/moby/moby/releases/latest --jq .tag_name`, or
   the Docker Engine release notes page).
5. **Daemon settings** from `daemon.json`: no log rotation (`log-opts.max-size`) with
   the `json-file` driver → flag (container logs grow without limit). Mention
   `live-restore: false` only as information: with it on, containers keep running
   through a daemon upgrade.

## Output

One status line per host (`residencehome 29.6.0 → 29.9.2 available (apt, resolute)`),
then findings. An upgrade command is a suggestion: `sudo apt-get install --only-upgrade
docker-ce docker-ce-cli containerd.io docker-compose-plugin`; it restarts the daemon,
so it runs only on a yes.
