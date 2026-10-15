#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
BACKUPS="$TARGET/.demiurge-backup"
source "$REPO/shared.sh"

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

unlink_owned "$TARGET/agents/$DEMIURGE_AGENT"
for skill in "$TARGET"/skills/*; do
  is_demiurge_skill "$(basename "$skill")" || continue
  unlink_owned "$skill"
done

if [ -d "$BACKUPS" ] && [ -n "$(ls -A "$BACKUPS")" ]; then
  echo
  echo "Files that install.sh moved aside are still in $BACKUPS."
  echo "They were not restored. Copy back whatever you want to keep."
fi
