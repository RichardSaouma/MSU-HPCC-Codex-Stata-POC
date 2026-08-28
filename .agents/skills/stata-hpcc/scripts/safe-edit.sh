#!/usr/bin/env bash
# Preserve a file's current state before editing it, and record the change.
# Usage: bash safe-edit.sh /abs/path/to/file [note]
set -euo pipefail

TARGET="${1:?usage: safe-edit.sh /abs/path/to/file [note]}"
NOTE="${2:-}"

if [ ! -e "$TARGET" ]; then
  echo "does not exist yet — nothing to preserve: $TARGET"
  exit 0
fi

DIR="$(cd "$(dirname "$TARGET")" && pwd)"
PROJ="$DIR"
while [ "$PROJ" != "/" ] && [ ! -d "$PROJ/.git" ]; do PROJ="$(dirname "$PROJ")"; done
[ -d "$PROJ/.git" ] || PROJ="$DIR"

if [ -d "$PROJ/.git" ] && git -C "$PROJ" ls-files --error-unmatch "$TARGET" >/dev/null 2>&1; then
  if [ -z "$(git -C "$PROJ" status --porcelain -- "$TARGET")" ]; then
    echo "tracked and clean in git — history is safe, no backup needed"
    ACTION="modified (git-tracked)"
  else
    ACTION="modified (uncommitted changes present)"
  fi
else
  ACTION="modified"
fi

if [ "$ACTION" != "modified (git-tracked)" ]; then
  mkdir -p "$PROJ/.backups"
  STAMP="$(date +%Y%m%d-%H%M%S)"
  BAK="$PROJ/.backups/$(basename "$TARGET").$STAMP"
  cp -p "$TARGET" "$BAK"
  echo "backed up to: $BAK"
fi

mkdir -p "$PROJ/logs"
printf '%s\t%s\t%s\t%s\n' "$(date +%Y-%m-%dT%H:%M:%S)" "$ACTION" "$TARGET" "$NOTE" \
  >> "$PROJ/logs/file-changes.log"
echo "logged to: $PROJ/logs/file-changes.log"
