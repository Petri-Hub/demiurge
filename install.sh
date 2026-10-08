#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
STAMP="$(date +%Y%m%d-%H%M%S)"

usage() {
  echo "Usage: ./install.sh [--demiurge]"
  echo "Links demiurge agents and skills into \$CLAUDE_HOME (default: ~/.claude)."
  echo "  --demiurge  link only the Demiurge agent and the skills it uses"
  echo "To remove them, run ./uninstall.sh."
}

wanted_agent() {
  [ "$MODE" = all ] || [ "$1" = Demiurge.md ]
}

wanted_skill() {
  [ "$MODE" = all ] && return 0
  case "$1" in
    forge-*|pipeline-demiurge-*|workspace-structural-protocol|workspace-lifecycle-protocol|workspace-evolution-protocol) return 0 ;;
  esac
  return 1
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

MODE=all
case "${1:-}" in
  "") ;;
  --demiurge) MODE=demiurge ;;
  -h|--help) usage; exit 0 ;;
  *) usage; exit 1 ;;
esac

mkdir -p "$TARGET/agents" "$TARGET/skills"
for agent in "$REPO"/agents/*.md; do
  wanted_agent "$(basename "$agent")" || continue
  link "$agent" "$TARGET/agents/$(basename "$agent")"
done
for skill in "$REPO"/skills/*/; do
  skill="${skill%/}"
  wanted_skill "$(basename "$skill")" || continue
  link "$skill" "$TARGET/skills/$(basename "$skill")"
done

echo
echo "Done. Agents read skills from ~/.claude/skills, so allow it in settings.json:"
echo '  "permissions": { "allow": ["Read(~/.claude/skills/**)"] }'
if [ "$TARGET" != "$HOME/.claude" ]; then
  echo "CLAUDE_HOME is $TARGET: agents still look in ~/.claude/skills, so make that path resolve to $TARGET/skills."
fi
