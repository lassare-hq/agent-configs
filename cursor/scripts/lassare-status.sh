#!/bin/bash
# Resolve project root: script lives at .cursor/scripts/ so project root is ../..
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Lassare Status ==="

if [ -f "$PROJECT_ROOT/.lassare/mode.txt" ]; then
  MODE=$(cat "$PROJECT_ROOT/.lassare/mode.txt" | tr -d '[:space:]')
else
  MODE="inline"
fi
echo "Mode: $MODE"

DIALOG_FILE="$PROJECT_ROOT/.lassare/inline-dialog.txt"
if [ -f "$DIALOG_FILE" ]; then
  DIALOG=$(cat "$DIALOG_FILE" | tr -d '[:space:]')
else
  DIALOG="on"
fi
echo "Inline dialog: $DIALOG (gates dangerous commands with OS popup when in inline mode)"

echo ""
echo "Commands:"
echo "  /lassare-slack       - Slack mode (hook gates dangerous commands; set Auto-Run in Sandbox + Allow All)"
echo "  /lassare-inline      - Inline mode (Cursor Agent settings control approvals)"
echo "  /lassare-dialog-on   - Enable OS dialog for dangerous commands in inline mode"
echo "  /lassare-dialog-off  - Disable OS dialog (dangerous commands pass through)"
