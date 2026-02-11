#!/bin/bash
# Permission Request hook: Request approval via Slack for dangerous commands
#
# Strategy:
# - Inline mode: Allow everything (Gemini CLI handles approval)
# - Slack mode: Gate dangerous commands via Slack, allow safe ones
#
# Dangerous commands are blocked unless user added them to tools.shell.autoApprove
#
# Gemini hook format: Receives JSON via stdin, returns JSON via stdout
# Output: {"decision": "allow"} or {"decision": "deny", "reason": "..."}

MODE_FILE=".lassare/mode.txt"
SETTINGS_FILE=".gemini/settings.json"

# Dangerous command patterns (require Slack approval)
DANGEROUS_PATTERNS=(
    "rm -rf"
    "rm -r "
    "rmdir"
    "git push --force"
    "git push -f"
    "git reset --hard"
    "git clean -fd"
    "chmod 777"
    "chmod -R"
    "chown -R"
    "sudo "
    "curl.*|.*sh"
    "curl.*|.*bash"
    "wget.*|.*sh"
    "wget.*|.*bash"
    "dd if="
    "mkfs"
    "format "
    "> /dev/"
    "shutdown"
    "reboot"
    "init 0"
    "init 6"
    "kill -9"
    "killall"
    "pkill"
    "npm publish"
    "pip upload"
    "docker rm"
    "docker rmi"
    "kubectl delete"
)

# Check if command matches any dangerous pattern
is_dangerous() {
    local cmd="$1"
    for pattern in "${DANGEROUS_PATTERNS[@]}"; do
        if echo "$cmd" | grep -qiE "$pattern"; then
            return 0  # dangerous
        fi
    done
    return 1  # safe
}

# Check if command matches user's autoApprove list
is_auto_approved() {
    local cmd="$1"
    local auto_approve
    auto_approve=$(jq -r '.tools.shell.autoApprove // [] | .[]' "$SETTINGS_FILE" 2>/dev/null)

    if [ -z "$auto_approve" ]; then
        return 1  # no autoApprove list
    fi

    while IFS= read -r prefix; do
        if [[ "$cmd" == "$prefix"* ]]; then
            return 0  # user trusts this
        fi
    done <<< "$auto_approve"

    return 1  # not in autoApprove
}

# Read hook input first (Gemini sends JSON via stdin)
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // .tool_input.file_path // "action"' 2>/dev/null | head -c 500 || echo "action")

# Auto-allow .lassare/ file operations (mode switching, marker cleanup)
if echo "$COMMAND" | grep -qE '\.lassare/(mode\.txt|stop-asked-marker)'; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Always allow 'ask' tool without approval
if [ "$TOOL_NAME" = "ask" ]; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Only gate shell commands for now
if [ "$TOOL_NAME" != "run_shell_command" ]; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Check mode
if [ -f "$MODE_FILE" ]; then
    MODE=$(cat "$MODE_FILE" | tr -d '[:space:]')
else
    MODE="inline"
fi

# Inline mode: allow everything, Gemini CLI handles approval
if [ "$MODE" != "slack" ]; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Extract command
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // "action"' 2>/dev/null | head -c 500 || echo "action")

# Check if user explicitly trusts this command
if is_auto_approved "$COMMAND"; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Check if command is dangerous
if ! is_dangerous "$COMMAND"; then
    # Safe command: allow without Slack
    echo '{"decision": "allow"}'
    exit 0
fi

# Dangerous command in Slack mode: require Slack approval

# Get MCP URL and API key from settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
    # No settings file, allow (fail open)
    echo '{"decision": "allow"}'
    exit 0
fi

MCP_URL=$(jq -r '.mcpServers.lassare.url' "$SETTINGS_FILE" 2>/dev/null)
API_KEY=$(jq -r '.mcpServers.lassare.headers.Authorization' "$SETTINGS_FILE" 2>/dev/null | sed 's/Bearer //')

if [ -z "$MCP_URL" ] || [ "$MCP_URL" = "null" ] || [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
    # No MCP config, allow (fail open)
    echo '{"decision": "allow"}'
    exit 0
fi

# Build action description
ACTION="run_shell_command: $COMMAND"
ACTION_ESCAPED=$(printf '%s' "$ACTION" | jq -Rs '.')

# Call approve tool via Slack
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
                \"context\": \"Gemini CLI: dangerous command detected\"
            }
        }
    }" 2>/dev/null)

# Parse SSE response (MCP uses Server-Sent Events)
RESULT_LINE=$(echo "$RESPONSE" | grep '^data: ' | grep '"result"' | tail -1 | sed 's/^data: //')
TEXT_CONTENT=$(echo "$RESULT_LINE" | jq -r '.result.content[0].text // ""' 2>/dev/null)
APPROVED=$(echo "$TEXT_CONTENT" | jq -r '.approved // false' 2>/dev/null)

if [ "$APPROVED" = "true" ]; then
    echo '{"decision": "allow"}'
    exit 0
else
    echo '{"decision": "deny", "reason": "Denied via Slack"}'
    exit 0
fi
