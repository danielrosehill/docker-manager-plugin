#!/usr/bin/env bash
# Resolve docker-manager's user data directory: where the user's preferences
# and saved audit reports live, outside the plugin, so they survive updates.
#
#   scripts/paths.sh          -> data dir, which rule picked it, whether prefs exist
#   scripts/paths.sh dir      -> data dir only
#   scripts/paths.sh prefs    -> preferences file path (user copy, else the shipped example)
#   scripts/paths.sh init     -> create the data dir and copy the example preferences in (never overwrites)
#
# Resolution order (first match wins):
#   1. $DOCKER_MANAGER_HOME                     explicit override
#   2. $CLAUDE_USER_DATA/docker-manager         shared user-data root, if set
#   3. ~/.claude-user-data/docker-manager       if ~/.claude-user-data exists
#   4. ${XDG_DATA_HOME:-~/.local/share}/claude-plugins/docker-manager  if that root exists
#   5. ~/.claude-user-data/docker-manager       default
# Never ~/.claude: that is the agent's own state, not user content.
set -euo pipefail

NAME=docker-manager
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
XDG_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/claude-plugins"

if [[ -n "${DOCKER_MANAGER_HOME:-}" ]]; then DIR="$DOCKER_MANAGER_HOME"; RULE="DOCKER_MANAGER_HOME"
elif [[ -n "${CLAUDE_USER_DATA:-}" ]]; then DIR="$CLAUDE_USER_DATA/$NAME"; RULE="CLAUDE_USER_DATA"
elif [[ -d "$HOME/.claude-user-data" ]]; then DIR="$HOME/.claude-user-data/$NAME"; RULE="existing ~/.claude-user-data"
elif [[ -d "$XDG_ROOT" ]]; then DIR="$XDG_ROOT/$NAME"; RULE="existing $XDG_ROOT"
else DIR="$HOME/.claude-user-data/$NAME"; RULE="default"; fi

EXAMPLE="$PLUGIN_ROOT/seeds/preferences.example.md"
case "${1:-}" in
  dir) echo "$DIR" ;;
  prefs) [[ -f "$DIR/preferences.md" ]] && echo "$DIR/preferences.md" || echo "$EXAMPLE" ;;
  init)
    mkdir -p "$DIR/reports"
    if [[ -f "$DIR/preferences.md" ]]; then echo "exists: $DIR/preferences.md"
    else cp "$EXAMPLE" "$DIR/preferences.md"; echo "created: $DIR/preferences.md"; fi ;;
  "")
    echo "data_dir: $DIR"; echo "rule: $RULE"; echo "plugin_root: $PLUGIN_ROOT"
    echo "preferences: $([[ -f "$DIR/preferences.md" ]] && echo "$DIR/preferences.md" || echo "missing (using shipped example; run init)")" ;;
  *) echo "usage: $0 [dir|prefs|init]" >&2; exit 2 ;;
esac
