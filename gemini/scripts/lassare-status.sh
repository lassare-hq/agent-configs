#!/bin/bash
# Show current Lassare mode and dialog settings (read-only)

echo "=== Lassare Status ==="

if [ -f ".lassare/mode.txt" ]; then
  MODE=$(cat .lassare/mode.txt | tr -d '[:space:]')
else
  MODE="inline"
fi
echo "Mode: $MODE"

if [ -f ".lassare/inline-dialog.txt" ]; then
  DIALOG=$(cat .lassare/inline-dialog.txt | tr -d '[:space:]')
else
  DIALOG="off"
fi
echo "Inline dialog: $DIALOG"

echo ""
echo "Commands:"
echo "  /lassare-slack       - Switch to Slack mode"
echo "  /lassare-inline      - Switch to inline mode"
echo "  /lassare-dialog-on   - Enable OS dialog for dangerous commands"
echo "  /lassare-dialog-off  - Disable OS dialog"
