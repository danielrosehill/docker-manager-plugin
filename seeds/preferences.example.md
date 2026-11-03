# Docker manager preferences

How your Docker hosts are *meant* to be set up. The audit skills compare what they
find against this file and flag the differences; the cleanup command respects it.
Edit it by hand, or tell the agent ("remember that frigate should never autostart")
and the `preferences` skill writes it here.

The YAML block is machine-read: keep the keys. Anything you leave out falls back to
the default shown. Prose rules go under **Notes** at the bottom.

```yaml
# Hosts to audit. transport:
#   local -> run on this machine
#   ssh   -> ssh <target> 'bash -s' < scripts/docker-audit.sh
#   tool  -> a remote-shell tool your agent already has (e.g. an MCP "run command" tool);
#            put its name in `tool:`
hosts:
  - name: local
    transport: local

# Persistent data. Every bind mount and named volume holding state should resolve
# under one of these roots. Docker's own volume dir (/var/lib/docker/volumes) counts
# as outside unless you list it.
volume_roots: [/srv/docker]
volume_root_exceptions: []        # source paths allowed elsewhere (sockets, /etc/localtime, device paths)

# Deployments. Each compose project's working dir should sit under one of these
# roots and, if deployment_must_be_git, be inside a git repo with a remote.
deployment_roots: [/srv/stacks]
deployment_must_be_git: true
# Master deployment repo: one repo per stack, all submodules of this one (skill deployment-master).
deployment_master:
  path: null                      # e.g. /srv/stacks; the master repo is checked out here
  repo: null                      # e.g. git@github.com:you/myhost-deployments.git
  new_repo_visibility: private    # default for repos created by adopt-deployment (asked each time anyway)
deployment_must_have_remote: true
allow_local_images: false         # images built on the host (no registry) are flagged unless true

# Autostart.
autostart:
  daemon_enabled_at_boot: true    # docker.service enabled in systemd
  default_policy: unless-stopped  # what a long-running service should have
  allowed_policies: [unless-stopped, always]
  never_autostart: []             # container names that must have restart policy "no"
  must_autostart: []              # container names that must have a policy in allowed_policies

# Watchtower.
watchtower:
  expected: true                  # flag if absent
  mode: all                       # all | label-opt-in (only com.centurylinklabs.watchtower.enable=true)
  exclude: []                     # containers that must NOT be auto-updated (databases, pinned apps)
  max_hours_since_session: 36     # flag if the last completed update session is older

# Engine.
engine:
  install_method: apt             # apt | snap | static | desktop
  flag_pending_updates: true

# Cleanup (used by /cleanup).
cleanup:
  never_prune_volumes: true       # volumes only ever removed one by one with a yes
  min_image_age_hours: 168        # don't prune unused images younger than this
  keep_build_cache: false

# Containers every check skips (buildx builders, throwaway test containers).
ignore_containers: [buildx_buildkit_*]
```

## Notes

Free-text preferences the agent should honour, one bullet each, newest last.
