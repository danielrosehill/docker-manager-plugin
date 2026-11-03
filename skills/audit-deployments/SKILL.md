---
name: audit-deployments
description: Check where each running Docker stack is deployed from - every container traced to its compose project, working directory and compose file, whether that sits under the user's deployment root, is a git repo with a remote and no uncommitted drift, and flag containers started outside compose, images built locally or referenced only by ID, and stacks whose directory no longer exists. Read-only. Use for "where is this container deployed from", "are all my stacks in a deployment repo", "which containers aren't from compose", "deployment hygiene".
---

# Audit deployments

Procedure: `shared/running-on-hosts.md`. Sections: `containers`. Git checks run on the
host as extra commands (same transport).

## Checks

1. **Group by stack.** Group containers by `compose_project` + `compose_working_dir`.
   No compose labels → **started by hand** (`docker run`): flag, nothing records how to
   recreate it.
2. **Location.** Working dir not under any `deployment_roots` → flag. Run directories
   under `/root`, `/tmp` or a home dir that isn't a root are the usual culprits.
3. **Directory still there.** `test -f <compose file>` for each `compose_files` entry.
   Missing → flag: the stack can't be recreated from what's on disk.
4. **Git.** For each working dir (when `deployment_must_be_git`):
   `git -C <dir> rev-parse --show-toplevel`, `git -C <dir> remote -v`,
   `git -C <dir> status --porcelain | head`, `git -C <dir> log -1 --format=%cs`.
   Not a repo → flag. No remote while `deployment_must_have_remote` → flag. Uncommitted
   changes → flag with the file names (drift between server and repo). Several stacks in
   one repo is fine; report the repo once.
5. **Images.** `image` with no registry and no tag (`foo:local`, `<project>-<service>`)
   is built on the host: fine if `allow_local_images`, else flag; either way note that
   Watchtower can't update it. An `image` that is a bare hex ID → flag: the tag was
   overwritten or removed and nothing names what's running.

## Output

A table per host: stack · working dir · repo (remote or "none") · state
(clean / N changed / missing) · containers. Then the flags. Skip `ignore_containers`.
If a master deployment repo is configured (`deployment_master`), also run its
`bin/status.sh` and flag stacks missing from `stacks.yaml`. Fixes: `adopt-deployment`
for loose stacks, `deployment-master` to create or update the master repo.
