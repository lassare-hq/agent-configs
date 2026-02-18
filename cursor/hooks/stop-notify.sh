#!/bin/bash
# Stop hook: Ask user via Slack before allowing Cursor to stop
# Only active when in Slack mode
#
# Logic:
# 1. Calls ask tool: "Cursor is stopping. Anything else?"
# 2. Waits for user response (blocking, up to 15 min)
# 3. If user says "no/done/stop/ok" -> BLOCKS stop with instruction to run /lassare-inline
#    (Cursor runs the command, switches mode in-context, then stops on next attempt)
# 4. If timeout/no response -> same as above (block + switch instruction)
# 5. If user gives a task -> blocks stop, includes task
#
# Why block instead of allow? If we allow stop silently after switching mode.txt,
# Cursor doesn't notice the mode change and keeps using Slack MCP if session resumes.
# Blocking forces Cursor to run /lassare-inline so the mode switch happens in-context.
#
# Cursor hook format: Receives JSON via stdin
# Returns JSON with followup_message to block stop, or exits 0 to allow stop

# Resolve project root: hook lives at .cursor/hooks/ so project root is ../..
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(cd "$HOOK_DIR/../.." && pwd)"

MODE_FILE="$PROJECT_ROOT/.lassare/mode.txt"
MCP_CONFIG="$PROJECT_ROOT/.cursor/mcp.json"
STOP_MARKER="$PROJECT_ROOT/.lassare/stop-asked-marker"

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
    # Mode is still slack here — the previous task was completed.
    # Allow stop without switching (user explicitly gave a task and it's done).
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
    ANSWER_WITH_CLEANUP=$(printf '%s\n\n[After completing this task, run: rm -f %s]' "$ANSWER" "$STOP_MARKER")
    ANSWER_ESCAPED=$(printf '%s' "$ANSWER_WITH_CLEANUP" | jq -Rs '.')
    echo "{\"followup_message\": $ANSWER_ESCAPED}"
    exit 0
fi
if echo "$ANSWER" | grep -qiE '\b(no|done|stop|nope|nothing|bye|exit|quit|end|finished|that.s all|all good)\b'; then
    # User confirmed stop - switch mode file and block stop with switch instruction
    # Cursor will run /lassare-inline (which updates in-context mode), then stop naturally
    # On next stop attempt, hook sees inline mode and allows immediately (exit 0 above)
    echo "inline" > "$MODE_FILE"
    rm -f "$STOP_MARKER"
    echo '{"followup_message": "Slack session ended. Run /lassare-inline to switch to inline mode, then you may stop."}'
    exit 0
fi

# User gave task - return followup message to continue
if [ -n "$ANSWER" ]; then
    touch "$STOP_MARKER"
    # Escape JSON to prevent injection
    ANSWER_WITH_CLEANUP=$(printf '%s\n\n[After completing this task, run: rm -f %s]' "$ANSWER" "$STOP_MARKER")
    ANSWER_ESCAPED=$(printf '%s' "$ANSWER_WITH_CLEANUP" | jq -Rs '.')
    echo "{\"followup_message\": $ANSWER_ESCAPED}"
    exit 0
else
    # No response or timeout - switch mode file and block stop with switch instruction
    echo "inline" > "$MODE_FILE"
    rm -f "$STOP_MARKER"
    echo '{"followup_message": "Slack session timed out. Run /lassare-inline to switch to inline mode, then you may stop."}'
    exit 0
fi
