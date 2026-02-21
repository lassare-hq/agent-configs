#!/bin/bash
# Resolve project root: script lives at .cursor/scripts/ so project root is ../..
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

mkdir -p "$PROJECT_ROOT/.lassare"
echo "inline" > "$PROJECT_ROOT/.lassare/mode.txt"
rm -f "$PROJECT_ROOT/.lassare/stop-asked-marker"

DIALOG_FILE="$PROJECT_ROOT/.lassare/inline-dialog.txt"
if [ -f "$DIALOG_FILE" ]; then
  DIALOG=$(cat "$DIALOG_FILE" | tr -d '[:space:]')
else
  DIALOG="on"
fi

echo "Switched to INLINE mode (dialog: $DIALOG)"
