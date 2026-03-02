#!/bin/bash
# lassare-config v1.0.0 — https://github.com/lassare-hq/agent-configs
# Switch to inline mode
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
mkdir -p "$PROJECT_ROOT/.lassare"
echo "inline" > "$PROJECT_ROOT/.lassare/mode.txt"

# Report dialog state
DIALOG_FILE="$PROJECT_ROOT/.lassare/inline-dialog.txt"
if [ -f "$DIALOG_FILE" ]; then
    DIALOG=$(cat "$DIALOG_FILE" | tr -d '[:space:]')
else
    DIALOG="off"
fi
echo "Switched to INLINE mode (dialog: $DIALOG)"
