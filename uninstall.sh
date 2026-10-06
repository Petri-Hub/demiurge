#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
BACKUPS="$TARGET/.agenkit-backup"

usage() {
  echo "Usage: ./uninstall.sh"
  echo "Removes the links ./install.sh created in \$CLAUDE_HOME (default: ~/.claude)."
  echo "Only links pointing into this repository are removed; everything else is left alone."
}

unlink_owned() {
  local destination="$1"
  if [ -L "$destination" ] && [[ "$(readlink "$destination")" == "$REPO/"* ]]; then
    rm "$destination"
    echo "removed $destination"
  fi
}

case "${1:-}" in
  "") ;;
  -h|--help) usage; exit 0 ;;
  *) usage; exit 1 ;;
esac

for agent in "$REPO"/agents/*.md; do
  unlink_owned "$TARGET/agents/$(basename "$agent")"
done
for skill in "$REPO"/skills/*/; do
  skill="${skill%/}"
  unlink_owned "$TARGET/skills/$(basename "$skill")"
done

if [ -d "$BACKUPS" ] && [ -n "$(ls -A "$BACKUPS")" ]; then
  echo
  echo "Files that install.sh moved aside are still in $BACKUPS."
  echo "They were not restored. Copy back whatever you want to keep."
fi
