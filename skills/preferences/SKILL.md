---
name: preferences
description: Record or change how the user's Docker hosts are meant to be set up (hosts to manage and how to reach them, where persistent volumes should live, where deployments come from, autostart and restart-policy rules, Watchtower expectations, cleanup limits) in a preferences file outside the plugin. Use for "set up docker manager", "remember that X should never autostart", "volumes live under /srv/docker", "add my server", "don't let watchtower update postgres", "show my docker preferences".
---

# Docker preferences

The preferences file is the user's record of intent. The audit skills compare reality
against it; `/cleanup` respects its limits. It lives in the user's data dir, never in
the plugin, so plugin updates don't touch it.

## Find it

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/paths.sh"        # data dir, rule, whether preferences exist
"${CLAUDE_PLUGIN_ROOT}/scripts/paths.sh" init   # first time: copies the example in, never overwrites
```

The data dir is `$DOCKER_MANAGER_HOME`, else `$CLAUDE_USER_DATA/docker-manager`, else
`~/.claude-user-data/docker-manager`. The file is `preferences.md`: a YAML block the
skills read, plus a **Notes** list for rules that don't fit a key.

## First-time setup

Don't interview from a blank page. Propose values from what the hosts already show,
then ask the user to confirm or correct:

1. `init`, then add each host the user names to `hosts:`, with its transport.
2. On each host run the `containers` and `autostart` sections (procedure:
   `shared/running-on-hosts.md`) and infer the convention in use:
   - `volume_roots`: the common parent of most bind-mount sources.
   - `deployment_roots`: the common parent of most `compose_working_dir` values.
   - `autostart.default_policy`: the most common restart policy.
   - `watchtower.expected`: whether one is running.
3. Show the proposed block with the evidence for each value (e.g. "38 of 52 bind
   mounts are under /home/me/deployments"), write it on a yes.

## Recording a preference

When the user states one ("frigate must never autostart", "watchtower shouldn't touch
the databases"):

- If it maps to a key, edit that key in place (add the name to the list, change the
  value). Keep the comments and key order.
- Otherwise add a bullet under **Notes**, with the date: `- 2026-11-03: <rule>`.
- Confirm in one line what changed. No other output.

If the data dir sits inside a git repo, commit just that file
(`git -C <dir> add preferences.md && git -C <dir> commit -m "docker-manager: <change>"`).
Never `git add -A`: the root may hold other tools' work.

## Showing

"Show my docker preferences" → print the YAML block and Notes as they are.
