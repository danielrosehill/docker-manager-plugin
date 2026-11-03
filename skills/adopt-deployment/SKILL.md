---
name: adopt-deployment
description: Remediate a Docker stack that was brought up loosely - no git repo, compose file in a random place like /root or /tmp, or a container started by hand with docker run - into the intended shape - its own repo (asks public or private), secrets and data gitignored, living under the deployment root, added as a submodule of the master deployment repo. Use for "this stack isn't in git", "adopt this deployment", "bring X into the deployments repo", "make a repo for this container", after audit-deployments flags loose stacks.
---

# Adopt a loose deployment

Input: one or more stacks flagged by `audit-deployments` (no repo, outside the
deployment root, or no compose at all). Commands run on the host through its transport
(`shared/running-on-hosts.md`). Read `deployment_master` and `deployment_roots` from
preferences.

## 1. Ask once, for all of them

List the stacks with what each is, and ask: **public or private** (default private;
config dirs often hold account IDs and hostnames). Name: `<stack>-deployment` unless the
user's existing repos use another pattern. Check the name isn't taken.

## 2. Look before committing anything

For each stack dir: list files (skip data dirs), read any `.gitignore`, and check
for anything secret: `.env`, `*.env`, `*credentials*`, `*.key`, `*.pem`, tokens inside
JSON/YAML. Gitignore at least: `.env`, `*.env`, `!.env.example`, `data/`,
`__pycache__/`, `.venv/`, `*.log`, `*.bak-*`, credentials files. Large binaries
(models, archives) are ignored and their fetch step documented. If the dir already
contains a nested repo holding the compose file (e.g. `src/` with its own remote), don't
wrap it; that nested repo *is* the stack repo.

## 3. Repo

Create the remote (visibility from step 1), then in the stack dir:
`git init -b main`, `git add -A`, show the staged file list and check it for secrets,
commit (`Track live <stack> deployment from <host>`), add origin, push. Confirm with
`git ls-remote <url> main`.

## 4. Move it under the deployment root, if it's outside

Same directory **name** keeps the compose project name, so named volumes
(`<project>_<volume>`) are reused. Relative bind mounts move with the dir.

```bash
docker compose --project-directory <old> -f <old>/<compose> down     # brief outage: say so first
sudo mv <old> <root>/<stack> && sudo chown -R <user>:<user> <root>/<stack>
cd <root>/<stack> && docker compose up -d
```

Verify containers are up and the working-dir label is the new path. Absolute bind
mounts pointing into the old location have to be repointed first; check before moving.

## 5. No compose at all (`docker run` container)

Generate a compose file from `docker inspect`: image, name, restart policy, ports, env
(secrets go to `.env`, not the file), mounts, networks, labels, command. Show it to the
user. Recreating swaps the container, so only on a yes: `docker stop` + `docker rename
<name> <name>-old`, `docker compose up -d`, verify, then remove the old one.

## 6. Master repo

`git submodule add <url> <stack>` in the master, add the `stacks.yaml` entry (tier,
`enabled: true`), commit, push, `bin/status.sh`. If there is no master yet, run
`deployment-master` first.
