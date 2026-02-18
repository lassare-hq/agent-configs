#!/bin/bash
# Resolve project root: script lives at .cursor/scripts/ so project root is ../..
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Mode only. Agent updates .vscode/settings.json (YOLO off) when running this command.
mkdir -p "$PROJECT_ROOT/.lassare"
echo "inline" > "$PROJECT_ROOT/.lassare/mode.txt"
rm -f "$PROJECT_ROOT/.lassare/stop-asked-marker"

echo "Switched to INLINE mode (YOLO disabled — Cursor UI handles approvals)"
