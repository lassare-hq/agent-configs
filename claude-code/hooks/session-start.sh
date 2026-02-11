#!/bin/bash
# Session Start Hook - Reminds Claude about Slack mode
# Injects context so Claude knows to use mcp__lassare__ask for communication

MODE_FILE="$CLAUDE_PROJECT_DIR/.lassare/mode.txt"

# Check if we're in Slack mode
if [ -f "$MODE_FILE" ]; then
    MODE=$(cat "$MODE_FILE" | tr -d '[:space:]')
else
    MODE="inline"  # Default to inline if file missing
fi

if [ "$MODE" = "slack" ]; then
    # Output reminder that gets injected into Claude's context
    cat << 'EOF'
<session-start-hook>
SLACK NOTIFY MODE ACTIVE:
Throughout this session, use the `ask` MCP tool for ALL communication with the user.
Your FIRST action MUST be to greet the user via Slack and ask what they need.
</session-start-hook>
EOF
fi
