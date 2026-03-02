#!/bin/bash
# lassare-config v1.0.0 — https://github.com/lassare-hq/agent-configs
# Disable inline dialog for dangerous commands
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
mkdir -p "$PROJECT_ROOT/.lassare"
echo "off" > "$PROJECT_ROOT/.lassare/inline-dialog.txt"
echo "Inline dialog DISABLED — dangerous commands will pass through"
