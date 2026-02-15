#!/bin/bash
mkdir -p .lassare
echo "inline" > .lassare/mode.txt
rm -f .lassare/stop-asked-marker
echo "Switched to INLINE mode"
echo ""

# Check dialog state to show appropriate warning
DIALOG="off"
if [ -f ".lassare/inline-dialog.txt" ]; then
  DIALOG=$(cat .lassare/inline-dialog.txt | tr -d '[:space:]')
fi

if [ "$DIALOG" = "on" ]; then
  echo "Disable YOLO (Ctrl+Y) — dialog will handle approvals"
else
  echo "WARNING: Disable YOLO (Ctrl+Y) — dangerous commands will run without approval"
fi
