#!/bin/bash
# lassare-config v1.0.0 — https://github.com/lassare-hq/agent-configs
# Stop hook: Ask user via Slack before allowing Copilot to stop
# Only active when in Slack mode
#
# Logic:
# 1. If stop_hook_active=true (agent continuing from previous block) -> allow stop
# 2. If not slack mode -> allow stop
# 3. Calls ask tool: "Copilot is stopping. Anything else?"
# 4. If user says "done" etc -> allow stop, switch to inline
# 5. If user gives a task -> block stop with task as reason
# 6. If timeout/no response -> allow stop, switch to inline
#
# VS Code Copilot hook format (Stop):
#   Input: JSON via stdin with stop_hook_active flag
#   Output: hookSpecificOutput with decision:"block"|"allow"

ALLOW='{"continue":true,"hookSpecificOutput":{"hookEventName":"Stop","decision":"allow"}}'
BLOCK_FN() { echo "{\"continue\":true,\"hookSpecificOutput\":{\"hookEventName\":\"Stop\",\"decision\":\"block\",\"reason\":$1}}"; }

# Resolve project root: hook lives at .github/hooks/ so project root is ../..
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(cd "$HOOK_DIR/../.." && pwd)"

MODE_FILE="$PROJECT_ROOT/.lassare/mode.txt"
MCP_CONFIG="$PROJECT_ROOT/.vscode/mcp.json"

# Read stdin
INPUT=$(cat)

# If agent is continuing from a previous block, allow stop
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    echo "inline" > "$MODE_FILE"
    echo "$ALLOW"
    exit 0
fi

# Check mode
if [ -f "$MODE_FILE" ]; then
    MODE=$(cat "$MODE_FILE" | tr -d '[:space:]')
else
    MODE="inline"
fi

if [ "$MODE" != "slack" ]; then
    echo "$ALLOW"
    exit 0
fi

# Get MCP config
if [ ! -f "$MCP_CONFIG" ]; then
    echo "$ALLOW"
    exit 0
fi

MCP_URL=$(jq -r '.servers.lassare.url // .mcpServers.lassare.url' "$MCP_CONFIG" 2>/dev/null)
API_KEY=$(jq -r '.servers.lassare.headers.Authorization // .mcpServers.lassare.headers.Authorization' "$MCP_CONFIG" 2>/dev/null | sed 's/Bearer //')

# If API key contains ${input:...}, try reading from .lassare/api-key
if echo "$API_KEY" | grep -q '${input:'; then
    if [ -f "$PROJECT_ROOT/.lassare/api-key" ]; then
        API_KEY=$(cat "$PROJECT_ROOT/.lassare/api-key" | tr -d '[:space:]')
    else
        echo "$ALLOW"
        exit 0
    fi
fi

if [ -z "$MCP_URL" ] || [ "$MCP_URL" = "null" ] || [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
    echo "$ALLOW"
    exit 0
fi

# Ask user via Slack (15 min timeout)
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
                "question": "VS Code Copilot is stopping. Anything else? (continuation may be unreliable)",
                "context": "Reply with a task to continue, or say done to let Copilot stop. Not answering or saying done will switch back to inline mode. Note: Copilot may not reliably resume after your reply due to a known limitation."
            }
        }
    }' 2>/dev/null)

# Parse SSE response
RESULT_LINE=$(echo "$RESPONSE" | grep '^data: ' | grep '"result"' | tail -1 | sed 's/^data: //')
ANSWER=$(echo "$RESULT_LINE" | jq -r '.result.content[0].text // ""' 2>/dev/null | tr '[:upper:]' '[:lower:]')

# Check if user wants to stop
# First check for negations like "not done", "don't stop" — these mean "keep going"
if echo "$ANSWER" | grep -qiE '\b(not|don.t|do not|never)\b'; then
    ANSWER_ESCAPED=$(printf '%s' "$ANSWER" | jq -Rs '.')
    BLOCK_FN "$ANSWER_ESCAPED"
    exit 0
fi
if echo "$ANSWER" | grep -qiE '\b(no|done|stop|nope|nothing|bye|exit|quit|end|finished|that.s all|all good)\b'; then
    echo "inline" > "$MODE_FILE"
    echo "$ALLOW"
    exit 0
fi

# User gave task — block stop and relay task
if [ -n "$ANSWER" ]; then
    ANSWER_ESCAPED=$(printf '%s' "$ANSWER" | jq -Rs '.')
    BLOCK_FN "$ANSWER_ESCAPED"
    exit 0
else
    # No response or timeout — switch mode and allow stop
    echo "inline" > "$MODE_FILE"
    echo "$ALLOW"
    exit 0
fi
