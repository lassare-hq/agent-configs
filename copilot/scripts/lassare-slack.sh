#!/bin/bash
# lassare-config v1.0.0 — https://github.com/lassare-hq/agent-configs
# Switch to Slack mode
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
mkdir -p "$PROJECT_ROOT/.lassare"
echo "slack" > "$PROJECT_ROOT/.lassare/mode.txt"
echo "Switched to SLACK mode"
