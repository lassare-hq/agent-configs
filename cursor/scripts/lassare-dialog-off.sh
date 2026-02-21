#!/bin/bash
# Resolve project root: script lives at .cursor/scripts/ so project root is ../..
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

mkdir -p "$PROJECT_ROOT/.lassare"
echo "off" > "$PROJECT_ROOT/.lassare/inline-dialog.txt"
echo "Inline dialog: OFF — dangerous commands pass through without approval"
