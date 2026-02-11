#!/bin/bash
# Permission Request hook: Request approval via Slack buttons
# Uses the `approve` MCP tool for Approve/Deny button UI
#
# Returns:
# - hookSpecificOutput with decision:allow on Approve
# - hookSpecificOutput with decision:deny on Deny/timeout

MODE_FILE="$CLAUDE_PROJECT_DIR/.lassare/mode.txt"
MCP_CONFIG="$CLAUDE_PROJECT_DIR/.mcp.json"

# Read stdin for hook input (must happen before any exit)
INPUT=$(cat)

# Extract command/path for auto-allow checks
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // .tool_input.file_path // "action"' 2>/dev/null | head -c 400 || echo "action")

# Auto-allow .lassare/ file operations (mode switching, marker cleanup)
# These are just mode.txt and stop-asked-marker — safe in any mode
if echo "$COMMAND" | grep -qE '\.lassare/(mode\.txt|stop-asked-marker)'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
    exit 0
fi

# Check if we're in Slack mode
if [ -f "$MODE_FILE" ]; then
    MODE=$(cat "$MODE_FILE" | tr -d '[:space:]')
else
    MODE="inline"  # Default to inline
fi

# If not in Slack mode, exit without output (fall back to normal terminal prompt)
if [ "$MODE" != "slack" ]; then
    exit 0
fi

# Get MCP URL and API key from .mcp.json
if [ ! -f "$MCP_CONFIG" ]; then
    exit 0  # Fall back to terminal prompt
fi

MCP_URL=$(jq -r '.mcpServers.lassare.url' "$MCP_CONFIG" 2>/dev/null)
API_KEY=$(jq -r '.mcpServers.lassare.headers.Authorization' "$MCP_CONFIG" 2>/dev/null | sed 's/Bearer //')

if [ -z "$MCP_URL" ] || [ "$MCP_URL" = "null" ] || [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
    exit 0  # Fall back to terminal prompt
fi

# Extract permission details safely
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")

# Build action description for approve tool
ACTION="$TOOL_NAME: $COMMAND"

# Escape for JSON - use jq to properly escape
ACTION_ESCAPED=$(printf '%s' "$ACTION" | jq -Rs '.')

# Call Lassare MCP approve tool (blocking - waits for Slack button click)
RESPONSE=$(curl -s --max-time 300 \
    -X POST "$MCP_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d "{
        \"jsonrpc\": \"2.0\",
        \"id\": 1,
        \"method\": \"tools/call\",
        \"params\": {
            \"name\": \"approve\",
            \"arguments\": {
                \"action\": $ACTION_ESCAPED,
                \"context\": \"Claude Code permission request\"
            }
        }
    }" 2>/dev/null)

# Parse the response - extract JSON from SSE format (lines starting with "data: ")
RESULT_LINE=$(echo "$RESPONSE" | grep '^data: ' | grep '"result"' | tail -1 | sed 's/^data: //')

# Extract the text content which contains the JSON with approved field
TEXT_CONTENT=$(echo "$RESULT_LINE" | jq -r '.result.content[0].text // ""' 2>/dev/null)

# Parse the approved boolean from the text content
APPROVED=$(echo "$TEXT_CONTENT" | jq -r '.approved // false' 2>/dev/null)

# Return hook decision based on approval
if [ "$APPROVED" = "true" ]; then
    echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
else
    echo '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"deny","message":"Denied via Slack"}}}'
fi

exit 0
