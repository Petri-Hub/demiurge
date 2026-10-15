#!/usr/bin/env bash
set -euo pipefail

DEMIURGE_AGENT=Demiurge.md
REPO_URL="https://github.com/Petri-Hub/demiurge"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
BACKUPS="$TARGET/.demiurge-backup"

is_demiurge_skill() {
  case "$1" in
    forge-*|pipeline-demiurge-*|workspace-structural-protocol|workspace-lifecycle-protocol|workspace-evolution-protocol) return 0 ;;
    *) return 1 ;;
  esac
}

usage() {
  echo "Usage: ./uninstall.sh"
  echo "Removes the Demiurge agent and skills ./install.sh placed in \$CLAUDE_HOME (default: ~/.claude)."
  echo "Works for both copied and symlinked installs; anything else is left alone."
  echo "One-liner: curl -fsSL $REPO_URL/raw/main/uninstall.sh | bash"
}

remove_owned() {
  local destination="$1"
  if [ -L "$destination" ] || [ -e "$destination" ]; then
    rm -rf "$destination"
    echo "removed $destination"
  fi
}

case "${1:-}" in
  "") ;;
  -h|--help) usage; exit 0 ;;
  *) usage; exit 1 ;;
esac

remove_owned "$TARGET/agents/$DEMIURGE_AGENT"
for skill in "$TARGET"/skills/*; do
  [ -e "$skill" ] || [ -L "$skill" ] || continue
  is_demiurge_skill "$(basename "$skill")" || continue
  remove_owned "$skill"
done

if [ -d "$BACKUPS" ] && [ -n "$(ls -A "$BACKUPS")" ]; then
  echo
  echo "Files that install.sh moved aside are still in $BACKUPS."
  echo "They were not restored. Copy back whatever you want to keep."
fi
