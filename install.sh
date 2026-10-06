#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
STAMP="$(date +%Y%m%d-%H%M%S)"

usage() {
  echo "Usage: ./install.sh [--uninstall]"
  echo "Links agenkit agents and skills into \$CLAUDE_HOME (default: ~/.claude)."
}

link() {
  local source="$1" destination="$2"
  if [ -L "$destination" ]; then
    [ "$(readlink "$destination")" = "$source" ] && return
    rm "$destination"
  elif [ -e "$destination" ]; then
    local backup="$TARGET/.agenkit-backup/$STAMP"
    mkdir -p "$backup"
    mv "$destination" "$backup/$(basename "$destination")"
    echo "backed up $destination to $backup"
  fi
  ln -s "$source" "$destination"
  echo "linked $destination"
}

unlink_owned() {
  local destination="$1"
  if [ -L "$destination" ] && [[ "$(readlink "$destination")" == "$REPO/"* ]]; then
    rm "$destination"
    echo "removed $destination"
  fi
}

case "${1:-}" in
  "")
    mkdir -p "$TARGET/agents" "$TARGET/skills"
    for agent in "$REPO"/agents/*.md; do
      link "$agent" "$TARGET/agents/$(basename "$agent")"
    done
    for skill in "$REPO"/skills/*/; do
      skill="${skill%/}"
      link "$skill" "$TARGET/skills/$(basename "$skill")"
    done
    echo
    echo "Done. Agents read skills from ~/.claude/skills, so allow it in settings.json:"
    echo '  "permissions": { "allow": ["Read(~/.claude/skills/**)"] }'
    if [ "$TARGET" != "$HOME/.claude" ]; then
      echo "CLAUDE_HOME is $TARGET: agents still look in ~/.claude/skills, so make that path resolve to $TARGET/skills."
    fi
    ;;
  --uninstall)
    for agent in "$REPO"/agents/*.md; do
      unlink_owned "$TARGET/agents/$(basename "$agent")"
    done
    for skill in "$REPO"/skills/*/; do
      skill="${skill%/}"
      unlink_owned "$TARGET/skills/$(basename "$skill")"
    done
    ;;
  -h|--help) usage ;;
  *) usage; exit 1 ;;
esac
