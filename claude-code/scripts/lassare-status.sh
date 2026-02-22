#!/bin/bash
# Use CLAUDE_PROJECT_DIR (set by Claude Code) to avoid cwd issues
DIR="${CLAUDE_PROJECT_DIR:-.}"
if [ -f "$DIR/.lassare/mode.txt" ]; then
  echo "Mode: $(cat "$DIR/.lassare/mode.txt" | tr -d '[:space:]')"
else
  echo "Mode: inline (default)"
fi
