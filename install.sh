#!/usr/bin/env bash
set -euo pipefail

DEMIURGE_AGENT=Demiurge.md
REPO_URL="https://github.com/Petri-Hub/demiurge"
TARBALL_URL="https://github.com/Petri-Hub/demiurge/archive/refs/heads/main.tar.gz"
TARGET="${CLAUDE_HOME:-$HOME/.claude}"
STAMP="$(date +%Y%m%d-%H%M%S)"
MODE="copy"

is_demiurge_skill() {
  case "$1" in
    forge-*|pipeline-demiurge-*|workspace-structural-protocol|workspace-lifecycle-protocol|workspace-evolution-protocol) return 0 ;;
    *) return 1 ;;
  esac
}

usage() {
  echo "Usage: ./install.sh [--copy|--link] [--demiurge]"
  echo "Installs the Demiurge agent and its skills into \$CLAUDE_HOME (default: ~/.claude)."
  echo "  --copy      copy files (default; also used for curl | bash installs)"
  echo "  --link      symlink to this checkout instead (local development)"
  echo "  --demiurge  accepted for compatibility; this is now the default"
  echo "One-liner: curl -fsSL $REPO_URL/raw/main/install.sh | bash"
  echo "To remove them, run ./uninstall.sh."
}

backup_existing() {
  local destination="$1"
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    local backup="$TARGET/.demiurge-backup/$STAMP"
    mkdir -p "$backup"
    rm -rf "$backup/$(basename "$destination")"
    mv "$destination" "$backup/$(basename "$destination")"
    echo "backed up $destination to $backup"
  fi
}

install_entry() {
  local source="$1" destination="$2"
  if [ "$MODE" = "link" ]; then
    if [ -L "$destination" ]; then
      [ "$(readlink "$destination")" = "$source" ] && return
      rm "$destination"
    else
      backup_existing "$destination"
    fi
    ln -s "$source" "$destination"
    echo "linked $destination"
  else
    backup_existing "$destination"
    cp -R "$source" "$destination"
    echo "copied $destination"
  fi
}

for arg in "$@"; do
  case "$arg" in
    ""|--demiurge) ;;
    --copy) MODE="copy" ;;
    --link) MODE="link" ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

SOURCE_DIR=""
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
if [ -n "$SCRIPT_PATH" ] && [ -f "$SCRIPT_PATH" ]; then
  CANDIDATE="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
  if [ -d "$CANDIDATE/agents" ] && [ -d "$CANDIDATE/skills" ]; then
    SOURCE_DIR="$CANDIDATE"
  fi
fi

if [ -z "$SOURCE_DIR" ]; then
  if [ "$MODE" = "link" ]; then
    echo "error: --link needs a local checkout; use ./install.sh from a cloned repo." >&2
    exit 1
  fi
  command -v curl >/dev/null 2>&1 || { echo "error: need curl to download $TARBALL_URL" >&2; exit 1; }
  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT
  curl -fsSL "$TARBALL_URL" -o "$TMPDIR/demiurge.tar.gz"
  tar -xzf "$TMPDIR/demiurge.tar.gz" -C "$TMPDIR"
  SOURCE_DIR="$(echo "$TMPDIR"/demiurge-*)"
  [ -d "$SOURCE_DIR/agents" ] || { echo "error: download did not contain agents/" >&2; exit 1; }
fi

mkdir -p "$TARGET/agents" "$TARGET/skills"
install_entry "$SOURCE_DIR/agents/$DEMIURGE_AGENT" "$TARGET/agents/$DEMIURGE_AGENT"
for skill in "$SOURCE_DIR"/skills/*/ "$SOURCE_DIR"/examples/workspace/*/; do
  [ -e "$skill" ] || continue
  skill="${skill%/}"
  is_demiurge_skill "$(basename "$skill")" || continue
  install_entry "$skill" "$TARGET/skills/$(basename "$skill")"
done

echo
echo "Done. Agents read skills from ~/.claude/skills, so allow it in settings.json:"
echo '  "permissions": { "allow": ["Read(~/.claude/skills/**)"] }'
if [ "$TARGET" != "$HOME/.claude" ]; then
  echo "CLAUDE_HOME is $TARGET: agents still look in ~/.claude/skills, so make that path resolve to $TARGET/skills."
fi
