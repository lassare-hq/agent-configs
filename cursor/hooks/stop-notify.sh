#!/bin/bash
# Stop hook: Ask user via Slack before allowing Cursor to stop
# Only active when in Slack mode
#
# Cursor hook format: Receives JSON via stdin
# Returns JSON with followup_message to continue, or exits 0 to allow stop

MODE_FILE=".lassare/mode.txt"
MCP_CONFIG=".cursor/mcp.json"
STOP_MARKER=".lassare/stop-asked-marker"

# Check mode
if [ -f "$MODE_FILE" ]; then
    MODE=$(cat "$MODE_FILE" | tr -d '[:space:]')
else
    MODE="inline"
fi

if [ "$MODE" != "slack" ]; then
    exit 0
fi

# Check if marker exists (user gave a task earlier, now allow stop)
if [ -f "$STOP_MARKER" ]; then
    rm -f "$STOP_MARKER"
    echo "inline" > "$MODE_FILE"
    exit 0
fi

# Get MCP config
if [ ! -f "$MCP_CONFIG" ]; then
    exit 0
fi

MCP_URL=$(jq -r '.mcpServers.lassare.url' "$MCP_CONFIG" 2>/dev/null)
API_KEY=$(jq -r '.mcpServers.lassare.headers.Authorization' "$MCP_CONFIG" 2>/dev/null | sed 's/Bearer //')

if [ -z "$MCP_URL" ] || [ "$MCP_URL" = "null" ] || [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
    exit 0
fi

# Ask user via Slack
RESPONSE=$(curl -s --max-time 900 \
    -X POST "$MCP_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d '{
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "ask",
            "arguments": {
                "question": "Cursor is stopping. Anything else?",
                "context": "Reply with a task to continue, or say done to let Cursor stop. Not answering or saying done will switch back to inline mode."
            }
        }
    }' 2>/dev/null)

# Parse SSE response
RESULT_LINE=$(echo "$RESPONSE" | grep '^data: ' | grep '"result"' | tail -1 | sed 's/^data: //')
ANSWER=$(echo "$RESULT_LINE" | jq -r '.result.content[0].text // ""' 2>/dev/null | tr '[:upper:]' '[:lower:]')

# Check if user wants to stop
# Only match clear "stop" signals — NOT "yes" (ambiguous with "Anything else?" question)
# First check for negations like "not done", "don't stop" — these mean "keep going"
if echo "$ANSWER" | grep -qiE '\b(not|don.t|do not|never)\b'; then
    # Negation detected — user does NOT want to stop, treat as a task
    touch "$STOP_MARKER"
    ANSWER_WITH_CLEANUP=$(printf '%s\n\n[After completing this task, run: rm -f .lassare/stop-asked-marker]' "$ANSWER")
    ANSWER_ESCAPED=$(printf '%s' "$ANSWER_WITH_CLEANUP" | jq -Rs '.')
    echo "{\"followup_message\": $ANSWER_ESCAPED}"
    exit 0
fi
if echo "$ANSWER" | grep -qiE '\b(no|done|stop|nope|nothing|bye|exit|quit|end|finished|that.s all|all good)\b'; then
    echo "inline" > "$MODE_FILE"
    rm -f "$STOP_MARKER"
    exit 0
fi

# User gave task - return followup message to continue
if [ -n "$ANSWER" ]; then
    touch "$STOP_MARKER"
    # Escape JSON to prevent injection
    ANSWER_WITH_CLEANUP=$(printf '%s\n\n[After completing this task, run: rm -f .lassare/stop-asked-marker]' "$ANSWER")
    ANSWER_ESCAPED=$(printf '%s' "$ANSWER_WITH_CLEANUP" | jq -Rs '.')
    echo "{\"followup_message\": $ANSWER_ESCAPED}"
    exit 0
else
    # No response or timeout - switch to inline, clean marker, allow stop
    echo "inline" > "$MODE_FILE"
    rm -f "$STOP_MARKER"
    exit 0
fi
