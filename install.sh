#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
STAMP="$(date +%Y%m%d-%H%M%S)"

usage() {
  echo "Usage: ./install.sh"
  echo "Links demiurge agents and skills into \$CLAUDE_HOME (default: ~/.claude)."
  echo "To remove them, run ./uninstall.sh."
}

link() {
  local source="$1" destination="$2"
  if [ -L "$destination" ]; then
    [ "$(readlink "$destination")" = "$source" ] && return
    rm "$destination"
  elif [ -e "$destination" ]; then
    local backup="$TARGET/.demiurge-backup/$STAMP"
    mkdir -p "$backup"
    mv "$destination" "$backup/$(basename "$destination")"
    echo "backed up $destination to $backup"
  fi
  ln -s "$source" "$destination"
  echo "linked $destination"
}

case "${1:-}" in
  "") ;;
  -h|--help) usage; exit 0 ;;
  *) usage; exit 1 ;;
esac

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
