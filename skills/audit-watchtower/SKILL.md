---
name: audit-watchtower
description: Check Watchtower on a Docker host - is it installed and running, which fork and version, is the image current, its schedule and cleanup settings, which containers it updates or skips, and its update history (what it updated, when, failures, the last completed session). Read-only. Use for "is watchtower installed", "is watchtower working", "what did watchtower update", "watchtower history", "is watchtower up to date".
---

# Audit Watchtower

Procedure: `shared/running-on-hosts.md`. Sections: `watchtower containers`.

## Checks

1. **Present.** `installed: no` and `watchtower.expected: true` → flag and stop.
   More than one Watchtower container → flag (they race each other).
2. **Running and healthy**, with a restart policy that survives a reboot.
3. **Fork and version.** `containrrr/watchtower` is unmaintained (archived 2025) and
   breaks with newer Docker API versions; flag it and suggest the maintained fork
   `nicholas-fedor/watchtower`. Report `image_version_label` and `image_created`.
   To see whether a newer release exists, check the fork's latest GitHub release
   (`gh api repos/nicholas-fedor/watchtower/releases/latest --jq .tag_name`, or a web
   fetch). Watchtower does update itself if it isn't excluded, so a stale image means
   self-update is off or failing.
4. **Config** from the masked env and `cmd`: schedule (`WATCHTOWER_SCHEDULE` is a
   6-field cron with seconds; `WATCHTOWER_POLL_INTERVAL` otherwise, default 24 h),
   `CLEANUP`, `LABEL_ENABLE` (opt-in mode), `MONITOR_ONLY`, notifications. Compare
   with `watchtower.mode`.
5. **Coverage** from the container records:
   - mode `all`: containers labelled `com.centurylinklabs.watchtower.enable=false` are
     skipped; list them.
   - mode `label-opt-in`: only `...enable=true` are updated; list the ones that aren't.
   - anything in `watchtower.exclude` that Watchtower *will* update → flag (databases
     auto-updating across a major version is the usual casualty).
   - images built locally or referenced by ID can't be updated; list them as "not
     updatable", not as errors.
6. **History** from the log lines (last 30 days): per session date, `updated=`,
   `failed=`, `scanned=`; containers updated most; repeating warnings (e.g. a registry
   404 for one image every night means that image or tag no longer resolves). Time of
   last `Update session completed` older than `max_hours_since_session` → flag.

## Output

Status line (`watchtower nicholas-fedor 1.23.2, healthy, daily 04:00, last session
2026-11-03 04:00, 0 failed`), then findings, then a short history table:
date · updated · failed · containers.
