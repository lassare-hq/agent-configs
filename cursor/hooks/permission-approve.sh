#!/bin/bash
# Permission Request hook: Request approval via Slack buttons
# Returns decision:allow on Approve, decision:deny on Deny/timeout
#
# Cursor hook format: Receives JSON via stdin, returns JSON via stdout
# Output: {"decision": "allow"|"deny", "reason": "..."}
# Alternative: Exit code 0 = allow, exit code 2 = deny

MODE_FILE=".lassare/mode.txt"
MCP_CONFIG=".cursor/mcp.json"

# Read hook input first (Cursor sends JSON via stdin)
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // .tool_input.file_path // "action"' 2>/dev/null | head -c 400 || echo "action")

# Auto-allow .lassare/ file operations (mode switching, marker cleanup)
if echo "$COMMAND" | grep -qE '\.lassare/(mode\.txt|stop-asked-marker)'; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Check if we're in Slack mode
if [ -f "$MODE_FILE" ]; then
    MODE=$(cat "$MODE_FILE" | tr -d '[:space:]')
else
    MODE="inline"
fi

# If not in Slack mode, fall back to default (allow)
if [ "$MODE" != "slack" ]; then
    exit 0
fi

# Get MCP URL and API key
if [ ! -f "$MCP_CONFIG" ]; then
    exit 0
fi

MCP_URL=$(jq -r '.mcpServers.lassare.url' "$MCP_CONFIG" 2>/dev/null)
API_KEY=$(jq -r '.mcpServers.lassare.headers.Authorization' "$MCP_CONFIG" 2>/dev/null | sed 's/Bearer //')

if [ -z "$MCP_URL" ] || [ "$MCP_URL" = "null" ] || [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
    exit 0
fi

ACTION="$TOOL_NAME: $COMMAND"
ACTION_ESCAPED=$(printf '%s' "$ACTION" | jq -Rs '.')

# Call approve tool
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
                \"context\": \"Cursor permission request\"
            }
        }
    }" 2>/dev/null)

# Parse SSE response (MCP uses Server-Sent Events)
RESULT_LINE=$(echo "$RESPONSE" | grep '^data: ' | grep '"result"' | tail -1 | sed 's/^data: //')
TEXT_CONTENT=$(echo "$RESULT_LINE" | jq -r '.result.content[0].text // ""' 2>/dev/null)
APPROVED=$(echo "$TEXT_CONTENT" | jq -r '.approved // false' 2>/dev/null)

if [ "$APPROVED" = "true" ]; then
    # Return JSON decision: allow
    echo '{"decision": "allow"}'
    exit 0
else
    # Return JSON decision: deny
    echo '{"decision": "deny", "reason": "Denied via Slack"}'
    exit 2
fi
