#!/bin/bash
# Use CLAUDE_PROJECT_DIR (set by Claude Code) to avoid cwd issues
DIR="${CLAUDE_PROJECT_DIR:-.}"
mkdir -p "$DIR/.lassare"
echo "slack" > "$DIR/.lassare/mode.txt"
rm -f "$DIR/.lassare/stop-asked-marker"
echo "Switched to SLACK mode"
