#!/bin/bash
# lassare-config v1.0.0 — https://github.com/lassare-hq/agent-configs
# Show current Lassare mode and settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

MODE_FILE="$PROJECT_ROOT/.lassare/mode.txt"
DIALOG_FILE="$PROJECT_ROOT/.lassare/inline-dialog.txt"

if [ -f "$MODE_FILE" ]; then
    MODE=$(cat "$MODE_FILE" | tr -d '[:space:]')
else
    MODE="inline"
fi

if [ -f "$DIALOG_FILE" ]; then
    DIALOG=$(cat "$DIALOG_FILE" | tr -d '[:space:]')
else
    DIALOG="off"
fi

echo "Mode: $MODE"
echo "Inline dialog: $DIALOG"
echo ""
echo "Commands: /lassare-slack, /lassare-inline, /lassare-dialog-on, /lassare-dialog-off"
