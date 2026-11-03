---
name: watchtower-remediate
description: Fix the problems audit-watchtower finds - an image that no longer resolves (registry 404 every run, e.g. an upstream that stopped publishing), the unmaintained containrrr/watchtower that breaks on new Docker APIs, containers that must not auto-update (databases), missing or broken schedules, stale self-updates. Use for "fix watchtower", "watchtower keeps failing on X", "stop watchtower updating postgres", "switch to the maintained watchtower".
---

# Watchtower remediation

Run `audit-watchtower` first; fix only what it found. Each change is in a compose file,
so it is committed and pushed in that stack's repo (and the master repo pointer bumped,
see `deployment-master`). Commands run on the host through its transport.

## Image no longer resolves

Log: `Digest retrieval failed ... 404` or `pull access denied` for the same image
every night. The upstream withdrew or stopped publishing that tag.

1. Confirm: `docker pull <image>` fails. Look up the upstream's announcement for a
   replacement image.
2. If there is a maintained replacement, propose it (with its changelog risk); don't
   switch without a yes.
3. Otherwise pin what's running and stop Watchtower trying:
   - `docker image inspect <image> --format '{{index .Config.Labels "org.opencontainers.image.version"}}'`
     gives the running version; `docker tag <image> <repo>:<version>`.
   - compose: `image: <repo>:<version>`, `pull_policy: never`, label
     `com.centurylinklabs.watchtower.enable=false`, and a comment saying why and the date.
   - The image can't be pulled again, so keep a copy: `docker save <repo>:<version> | gzip
     > <stack>/image/<name>.tar.gz` with `image/` gitignored.
   - `docker compose up -d` (recreates the container: brief outage), verify healthy.

## Unmaintained Watchtower

`containrrr/watchtower` is archived and fails against newer Docker API versions.
Swap the image to `ghcr.io/nicholas-fedor/watchtower:latest` in its compose file; the
env vars and labels are compatible. `docker compose up -d`, then check its log shows a
schedule and no API errors.

## Exclusions

For each container in `watchtower.exclude` (or any database the user names): add the
label `com.centurylinklabs.watchtower.enable=false` in its compose file, `up -d`.
Pin the image to a major-version tag (`postgres:16`, not `latest`) so manual updates
stay deliberate.

## Schedule and settings

`WATCHTOWER_SCHEDULE` takes 6 cron fields (seconds first): `0 0 4 * * *` = 04:00
daily. Set `TZ`. `WATCHTOWER_CLEANUP=true` removes old images after updating. Prefer
`WATCHTOWER_ROLLING_RESTART=true` only where stacks tolerate it.

## Verify

Next session in the log: `Update session completed ... failed=0` and the warning gone.
If it can't wait, a one-off check without updating:
`docker run --rm -v /var/run/docker.sock:/var/run/docker.sock ghcr.io/nicholas-fedor/watchtower --run-once --monitor-only`.
