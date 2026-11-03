#!/usr/bin/env bash
# One line per stack: tier, enabled, git state of its repo, running container count.
set -uo pipefail
cd "$(dirname "$0")/.."
printf '%-24s %-6s %-5s %-10s %s\n' STACK TIER ON GIT CONTAINERS
while IFS=$'\t' read -r name path compose tier enabled; do
  dirty=$(git -C "$path" status --porcelain 2>/dev/null | wc -l)
  ahead=$(git -C "$path" rev-list --count @{u}..HEAD 2>/dev/null || echo "?")
  git_state=$([[ $dirty -gt 0 ]] && echo "${dirty}dirty" || echo clean)
  [[ "$ahead" != "0" ]] && git_state+="+${ahead}unpushed"
  cdir=$(dirname "$path/$compose")
  up=$(docker ps --filter "label=com.docker.compose.project.working_dir=$(cd "$cdir" && pwd)" -q | wc -l)
  printf '%-24s %-6s %-5s %-10s %s\n' "$name" "$tier" "$enabled" "$git_state" "$up running"
done < <(bin/stacks.py --all)
