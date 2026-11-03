#!/usr/bin/env bash
# Bring stacks up from this master repo, tier by tier.
#   bin/up.sh                 all enabled stacks
#   bin/up.sh app1 app2       just these
#   bin/up.sh --pull ...      first fast-forward each submodule to its remote branch head
#   bin/up.sh --dry-run ...   print what would run
# Never runs `down`; compose leaves containers whose config is unchanged alone.
set -euo pipefail
cd "$(dirname "$0")/.."
PULL=0; DRY=0; NAMES=()
for a in "$@"; do case "$a" in --pull) PULL=1;; --dry-run) DRY=1;; *) NAMES+=("$a");; esac; done
run() { if ((DRY)); then echo "+ $*"; else "$@"; fi; }
run git submodule update --init
while IFS=$'\t' read -r name path compose tier enabled; do
  echo "== [$tier] $name"
  if ((PULL)); then run git -C "$path" pull --ff-only; fi
  run docker compose --project-directory "$(dirname "$path/$compose")" -f "$path/$compose" up -d
done < <(bin/stacks.py "${NAMES[@]}")
