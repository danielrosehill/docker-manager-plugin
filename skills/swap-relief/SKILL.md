---
name: swap-relief
description: Diagnose and clear a Docker host's full swap - which processes and containers hold swapped memory, whether RAM can absorb it, then a safe swapoff/swapon cycle, plus the lasting fixes (container memory limits, swappiness, more RAM or swap). Use for "swap is full", "clean the swap", "server is swapping", "clear swap on the docker host".
---

# Swap relief

Commands run on the host through its transport (`shared/running-on-hosts.md`).
`swapon`/`swapoff` live in `/usr/sbin`, which may not be on a non-root PATH; use full paths.

## 1. Look

```bash
free -m; sudo /usr/sbin/swapon --show; cat /proc/sys/vm/swappiness
for p in /proc/[0-9]*; do s=$(awk '/VmSwap/{print $2}' $p/status 2>/dev/null)
  [ -n "$s" ] && [ "$s" -gt 102400 ] && echo "$s kB $(cat $p/comm) pid=${p#/proc/}"; done | sort -rn | head -15
```

Map big swappers to containers: `cat /proc/<pid>/cgroup` shows `docker-<id>.scope`;
`docker ps --no-trunc` matches the id. VMs (`qemu-system-*`) and model servers are the
usual holders.

## 2. Decide

Full swap with plenty of available RAM is mostly stale pages: harmless, but it
leaves no headroom for a real spike. Clearing it is safe only if
`available RAM − swap used` stays above a margin (4 GB, or 15 % of RAM, whichever is
larger). Below that, `swapoff` can trigger the OOM killer: don't do it; go to step 4.

## 3. Clear (on the user's request)

```bash
free -m | awk '/Mem/{a=$7} /Swap/{s=$3} END{exit !(a-s>4000)}' \
  && sudo timeout 900 /usr/sbin/swapoff -a && sudo /usr/sbin/swapon -a
free -m
```

Takes seconds to minutes and is I/O heavy. Report swap before and after, and available
RAM after.

## 4. Lasting fixes (suggest, don't apply)

Swap refills if memory pressure is real. Name the top consumers, then: `mem_limit` /
`deploy.resources.limits.memory` on the hungry containers in their compose files; stop
idle VMs; `vm.swappiness` (10 is already low; going lower trades swap for OOM risk);
a larger swap file; more RAM. Re-check a day later.
