---
name: engine-auto-update
description: Keep Docker Engine, containerd and the Compose plugin updated automatically on Ubuntu/Debian hosts by adding Docker's apt repo to unattended-upgrades, then prove it with a dry run - including the traps that silently block it (wrong origin pattern, held packages, stale package lists aborting the whole run, apt source for the wrong OS release). Use for "keep docker updated automatically", "auto-update the docker engine", "why isn't docker updating", "apply the pending docker upgrade".
---

# Engine auto-update

For hosts with `engine.install_method: apt` (Docker's own repo, `download.docker.com`).
Snap, static or Desktop installs: say this skill doesn't apply and stop. Commands run on
the host through its transport (`shared/running-on-hosts.md`); all need sudo.

## 1. Preconditions

- `audit-engine` first. A `docker_apt_suite` that doesn't match `os_codename`, or
  `none`, has to be fixed before anything else (add/repoint the deb822 source in
  `/etc/apt/sources.list.d/docker.sources` to the current codename), or nothing will
  ever update.
- `systemctl is-enabled unattended-upgrades apt-daily.timer apt-daily-upgrade.timer`.
- `apt-mark showhold`: a held `docker-ce`/`containerd.io` blocks updates. Ask before
  unholding; someone may have held it on purpose. Look for a note in the host's docs first.

## 2. Allow Docker's origin

Docker's `Release` file has `Origin: Docker`, `Label: Docker CE`, `Suite: <codename>`
and **no `Codename:` field**, so a pattern with `codename=` never matches (the dry run
shows the Docker package list "Marking not allowed ... -32768 pin"). Match on
`archive=`:

```bash
printf '%s\n' '// Docker Engine, containerd, Compose from download.docker.com (docker-manager engine-auto-update)' \
  'Unattended-Upgrade::Origins-Pattern {' \
  '        "origin=Docker,label=Docker CE,archive=${distro_codename}";' \
  '};' | sudo tee /etc/apt/apt.conf.d/52unattended-upgrades-docker
```

## 3. Prove it

```bash
sudo apt-get update -qq
sudo unattended-upgrade --dry-run -v 2>&1 | grep -E 'Packages that will be upgraded|upgrade result'
```

Pass = `docker-ce` (and `containerd.io`, `docker-compose-plugin` if pending) in the
"will be upgraded" list. Note that "nothing pending" also lists nothing; check
`apt-cache policy docker-ce` installed vs candidate to tell the two apart.

If the run ends `upgrade result: False ... failed to download`, the package lists are
stale (a 404 on a superseded .deb). That aborts **every** unattended upgrade, not just
Docker's, so the host has been missing security updates too. `apt-get update` fixes
it for now; if it recurs, `apt-daily.timer` isn't running. Report it as a finding.

## 4. What an update does

Upgrading `docker-ce` restarts the daemon; `containerd.io` restarts every container.
With `live-restore: false` (the default) all containers stop and come back per their
restart policy, usually within a minute or two. Containers with policy `no` stay down
(see `audit-autostart`). Unattended runs happen at the `apt-daily-upgrade.timer` time
(`systemctl list-timers apt-daily-upgrade.timer`).

## 5. Applying a pending upgrade now (on a yes)

If the agent's own route to the host runs inside a container on that host (an MCP
shell in Docker), the upgrade kills the route mid-command. Run it detached:

```bash
sudo systemd-run --unit=docker-upgrade --collect \
  bash -c 'apt-get install -y --only-upgrade docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin'
```

Then wait, reconnect, and check `docker version`, `journalctl -u docker-upgrade`, and
that every `enabled` stack has its containers running (`bin/status.sh` in the master
repo, or `audit-autostart`).
