#!/bin/bash
# AfterAgent hook: Ask user via Slack before allowing Gemini to stop
# Only active when in Slack mode
#
# Logic:
# 1. Calls ask tool: "Gemini is stopping. Anything else?"
# 2. Waits for user response (blocking, up to 15 min)
# 3. If user says "no/done/stop/ok" -> DENIES stop with instruction to run /lassare-inline
#    (Gemini runs the command, switches mode in-context, then stops on next attempt)
# 4. If timeout/no response -> same as above (deny + switch instruction)
# 5. If user gives a task -> denies stop, feeds user's response as new task
#
# Why deny instead of allow? If we allow stop silently after switching mode.txt,
# Gemini doesn't notice the mode change and keeps using Slack MCP if session resumes.
# Denying forces Gemini to run /lassare-inline so the mode switch happens in-context.
#
# Gemini AfterAgent output format:
# - Allow stop: exit 0 with no output
# - Block stop + new task: {"decision": "deny", "reason": "..."}

MODE_FILE=".lassare/mode.txt"
SETTINGS_FILE=".gemini/settings.json"

# Read hook input (Gemini sends JSON via stdin)
INPUT=$(cat)

# Check if we're in Slack mode
if [ -f "$MODE_FILE" ]; then
    MODE=$(cat "$MODE_FILE" | tr -d '[:space:]')
else
    MODE="inline"
fi

# Exit early (allow stop) if not in Slack mode
if [ "$MODE" != "slack" ]; then
    exit 0
fi

# Get MCP URL and API key from settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
    exit 0  # Can't ask, allow stop
fi

MCP_URL=$(jq -r '.mcpServers.lassare.httpUrl // .mcpServers.lassare.url' "$SETTINGS_FILE" 2>/dev/null)
API_KEY=$(jq -r '.mcpServers.lassare.headers.Authorization' "$SETTINGS_FILE" 2>/dev/null | sed 's/Bearer //')

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
                "question": "Gemini is stopping. Anything else?",
                "context": "Reply with a task to continue, or say \"done\" to let Gemini stop. Not answering or saying done will switch back to inline mode."
            }
        }
    }' 2>/dev/null)

# Parse response - extract answer from SSE format
RESULT_LINE=$(echo "$RESPONSE" | grep '^data: ' | grep '"result"' | tail -1 | sed 's/^data: //')
ANSWER=$(echo "$RESULT_LINE" | jq -r '.result.content[0].text // ""' 2>/dev/null)
ANSWER_LOWER=$(echo "$ANSWER" | tr '[:upper:]' '[:lower:]')

# No response or timeout -> switch mode file and deny stop with switch instruction
if [ -z "$ANSWER" ]; then
    echo "inline" > "$MODE_FILE"
    echo "{\"decision\":\"deny\",\"reason\":\"Slack session timed out. Run /lassare-inline to switch to inline mode, then you may stop.\"}"
    exit 0
fi

# Check for negations like "not done", "don't stop" — these mean "keep going"
if echo "$ANSWER_LOWER" | grep -qiE '\b(not|don.t|do not|never)\b'; then
    ESCAPED_ANSWER=$(printf '%s' "$ANSWER" | jq -Rs '.' | sed 's/^"//;s/"$//')
    echo "{\"decision\":\"deny\",\"reason\":\"User responded via Slack with a new task: $ESCAPED_ANSWER\"}"
    exit 0
fi

# Check if user wants to stop
if echo "$ANSWER_LOWER" | grep -qiE '\b(no|done|stop|nope|nothing|bye|exit|quit|end|finished|that.s all|all good|ok)\b'; then
    # User confirmed stop - switch mode file and deny stop with switch instruction
    # Gemini will run /lassare-inline (which updates in-context mode), then stop naturally
    # On next stop attempt, hook sees inline mode and allows immediately (exit 0 above)
    echo "inline" > "$MODE_FILE"
    echo "{\"decision\":\"deny\",\"reason\":\"Slack session ended. Run /lassare-inline to switch to inline mode, then you may stop.\"}"
    exit 0
fi

# User gave a task -> deny stop, feed as new task
ESCAPED_ANSWER=$(printf '%s' "$ANSWER" | jq -Rs '.' | sed 's/^"//;s/"$//')
echo "{\"decision\":\"deny\",\"reason\":\"User responded via Slack with a new task: $ESCAPED_ANSWER\"}"

exit 0
