#!/bin/bash
# Stop hook: Ask user via Slack before allowing Claude to stop
# Only active when in Slack mode
#
# Logic:
# 1. Calls ask tool: "Claude is stopping. Anything else?"
# 2. Waits for user response (blocking, up to 15 min)
# 3. If user says "no/done/stop/ok" -> BLOCKS stop with instruction to run /lassare-inline
#    (Claude runs the skill, switches mode in-context, then stops on next attempt)
# 4. If timeout/no response -> same as above (block + switch instruction)
# 5. If user gives a task -> blocks stop, includes task
#
# Why block instead of allow? If we allow stop silently after switching mode.txt,
# Claude doesn't notice the mode change and keeps using Slack MCP if session resumes.
# Blocking forces Claude to run /lassare-inline so the mode switch happens in-context.

MODE_FILE="$CLAUDE_PROJECT_DIR/.lassare/mode.txt"
MCP_CONFIG="$CLAUDE_PROJECT_DIR/.mcp.json"
STOP_MARKER="$CLAUDE_PROJECT_DIR/.lassare/stop-asked-marker"

# Check if we're in Slack mode
if [ -f "$MODE_FILE" ]; then
    MODE=$(cat "$MODE_FILE" | tr -d '[:space:]')
else
    MODE="inline"  # Default to inline
fi

# Exit early (allow stop) if not in Slack mode
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

# Get MCP URL and API key from .mcp.json
if [ ! -f "$MCP_CONFIG" ]; then
    exit 0  # Can't ask, allow stop
fi

MCP_URL=$(jq -r '.mcpServers.lassare.url' "$MCP_CONFIG" 2>/dev/null)
API_KEY=$(jq -r '.mcpServers.lassare.headers.Authorization' "$MCP_CONFIG" 2>/dev/null | sed 's/Bearer //')

if [ -z "$MCP_URL" ] || [ "$MCP_URL" = "null" ] || [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
    exit 0  # Can't ask, allow stop
fi

# Call ask tool and wait for response (blocking, up to 15 min)
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
                "question": "Claude is stopping. Anything else?",
                "context": "Reply with a task to continue, or say \"done\" to let Claude stop. Not answering or saying done will switch back to inline mode."
            }
        }
    }' 2>/dev/null)

# Parse response - extract answer from SSE format
RESULT_LINE=$(echo "$RESPONSE" | grep '^data: ' | grep '"result"' | tail -1 | sed 's/^data: //')
ANSWER=$(echo "$RESULT_LINE" | jq -r '.result.content[0].text // ""' 2>/dev/null | tr '[:upper:]' '[:lower:]')

# Check if user wants to stop
# Only match clear "stop" signals — NOT "yes" (ambiguous with "Anything else?" question)
# First check for negations like "not done", "don't stop" — these mean "keep going"
if echo "$ANSWER" | grep -qiE '\b(not|don.t|do not|never)\b'; then
    # Negation detected — user does NOT want to stop, treat as a task
    touch "$STOP_MARKER"
    ESCAPED_ANSWER=$(printf '%s' "$ANSWER" | jq -Rs '.' | sed 's/^"//;s/"$//')
    echo "{\"decision\":\"block\",\"reason\":\"Stop hook feedback:\\nUser responded via Slack with a new task. Please address: $ESCAPED_ANSWER\\n\\n[After completing this task, run: rm -f .lassare/stop-asked-marker]\"}"
    exit 0
fi
if echo "$ANSWER" | grep -qiE '\b(no|done|stop|nope|nothing|bye|exit|quit|end|finished|that.s all|all good)\b'; then
    # User confirmed stop - switch mode file and block stop with switch instruction
    # Claude will run /lassare-inline (which updates in-context mode), then stop naturally
    # On next stop attempt, hook sees inline mode and allows immediately (exit 0 above)
    echo "inline" > "$MODE_FILE"
    rm -f "$STOP_MARKER"
    echo "{\"decision\":\"block\",\"reason\":\"Stop hook feedback:\\nSlack session ended. Run /lassare-inline to switch to inline mode, then you may stop.\"}"
    exit 0
fi

# User gave a task - block stop and tell Claude what to do
if [ -n "$ANSWER" ]; then
    # Create marker so next stop doesn't ask again (only ask once per cycle)
    touch "$STOP_MARKER"
    # Escape answer for safe JSON embedding
    ESCAPED_ANSWER=$(printf '%s' "$ANSWER" | jq -Rs '.' | sed 's/^"//;s/"$//')
    echo "{\"decision\":\"block\",\"reason\":\"Stop hook feedback:\\nUser responded via Slack with a new task. Please address: $ESCAPED_ANSWER\\n\\n[After completing this task, run: rm -f .lassare/stop-asked-marker]\"}"
else
    # No response or timeout - switch mode file and block stop with switch instruction
    echo "inline" > "$MODE_FILE"
    rm -f "$STOP_MARKER"
    echo "{\"decision\":\"block\",\"reason\":\"Stop hook feedback:\\nSlack session timed out. Run /lassare-inline to switch to inline mode, then you may stop.\"}"
    exit 0
fi

exit 0
