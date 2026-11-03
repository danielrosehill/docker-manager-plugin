---
name: deployment-master
description: Set up and run the master deployment repo shape - one git repo per Docker stack, all added as submodules of a single master repo checked out at the host's deployment root, with a stacks.yaml manifest (tier, enabled) and bin/up.sh and bin/status.sh to bring everything up and check drift. Use for "create a master deployment repo", "bring up all stacks", "add this stack to the deployments repo", "deployment status", "rebuild the server from the deployment repo".
---

# Deployment master

The intended shape for a Docker host managed by this plugin:

```
<deployment root>/            # master repo, e.g. ~/deployments  (preferences: deployment_master.path)
  README.md
  stacks.yaml                 # manifest: name, path, compose, repo, tier, enabled; external; unmanaged
  bin/stacks.py  bin/up.sh  bin/status.sh
  <stack>/                    # git submodule = that stack's own repo, holds its compose file
```

Each stack's compose working dir is `<root>/<stack>`, so its container labels, relative
bind mounts and volume names all stay stable. Secrets and data live in the stack dir and
are gitignored by the stack repo. The master repo holds no secrets. Templates:
`templates/deployment-master/`.

Run commands on the host through its transport (`shared/running-on-hosts.md`).

## Create one (host has stacks, no master yet)

1. Read `deployment_master` from preferences (`path`, `repo`, `visibility`). If unset,
   propose `path` = the most common parent of compose working dirs, `repo` =
   `<Host>-Deployments`, private, and ask once.
2. Check whether a master repo already exists before creating one: search the user's
   GitHub repos for `deploy`/`<host>` names and check if `path` is already a git repo.
3. Inventory every subdir of `path`: has a compose file? is a git repo with a remote?
   running? Stacks without a repo go through `adopt-deployment` first. If a stack's
   repo is nested (compose inside `src/`), the submodule is that nested repo path and
   the wrapper's data is ignored in the master `.gitignore`.
4. Create the remote repo, `git init -b main` in `path`, copy the template `bin/`,
   write `stacks.yaml` from the inventory (tier 0 for databases, brokers, object
   storage, the updater, monitoring; `enabled` = containers currently running from it),
   list stacks deployed from elsewhere under `external` and hand-started containers
   under `unmanaged`.
5. `git submodule add <url> <dir>` for each stack. On an existing clone git prints
   "Adding existing repo", which is expected; it does not re-clone or touch the files.
6. README (what, where, rules, fresh-host restore), commit, push. Then
   `bin/status.sh`: every row should be clean with containers running.

Moving an `external` stack into the tree changes its compose working dir and recreates
its containers. That needs a yes per stack, done like the move in `adopt-deployment`.

## Day to day

- **Status:** `bin/status.sh`; flag dirty or unpushed submodules (server-side edits not
  in git) and enabled stacks with 0 containers.
- **Bring up:** `bin/up.sh [--pull] [stack ...]`; `--dry-run` first when unsure. It never
  runs `down`.
- **Stack changed:** commit and push in the stack repo, then
  `git add <stack> && git commit -m "Bump <stack>"` in the master and push.
- **Fresh host:** `git clone --recurse-submodules <master> <path>`, restore each stack's
  `.env` and data from backup, `bin/up.sh`.
