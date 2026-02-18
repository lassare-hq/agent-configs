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

SETTINGS_FILE="$PROJECT_ROOT/.vscode/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  YOLO=$(grep -v '^[[:space:]]*//' "$SETTINGS_FILE" | jq -r '.["cursor.agent.yoloMode"] // false' 2>/dev/null)
else
  YOLO="false"
fi
echo "YOLO mode: $YOLO"

echo ""
echo "Commands:"
echo "  /lassare-slack   - Slack mode (enables YOLO, hook gates dangerous commands)"
echo "  /lassare-inline  - Inline mode (disables YOLO, Cursor UI handles approvals)"
