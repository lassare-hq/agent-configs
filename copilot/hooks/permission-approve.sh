#!/bin/bash
# lassare-config v1.0.0 — https://github.com/lassare-hq/agent-configs
# PreToolUse hook: Gate dangerous commands via Slack or OS dialog
#
# Strategy:
# 1. Only intercept shell/terminal tool calls
# 2. Auto-allow safe operations (.lassare/, lassare scripts)
# 3. Allow non-dangerous shell commands
# 4. For dangerous commands:
#    - Slack mode: request approval via Slack buttons
#    - Inline mode + dialog ON: show native OS dialog (macOS/Windows/Linux)
#    - Inline mode + dialog OFF: pass-through (allow)
# 5. Fail-closed: any error in Slack mode -> deny dangerous commands
#
# Config files:
#   .lassare/mode.txt           - "slack" or "inline" (default: inline)
#   .lassare/inline-dialog.txt  - "on" or "off" (default: on)
#
# VS Code Copilot hook format (PreToolUse):
#   Input: JSON via stdin with tool_name, tool_input, etc.
#   Output: JSON with hookSpecificOutput.permissionDecision

# Resolve project root: hook lives at .github/hooks/ so project root is ../..
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_ROOT="$(cd "$HOOK_DIR/../.." && pwd)"

MODE_FILE="$PROJECT_ROOT/.lassare/mode.txt"
DIALOG_FILE="$PROJECT_ROOT/.lassare/inline-dialog.txt"
MCP_CONFIG="$PROJECT_ROOT/.vscode/mcp.json"

# Read stdin for hook input (must happen before any exit)
INPUT=$(cat)

# Extract hook event and tool info
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // {}' 2>/dev/null)

# Only gate shell/terminal tools — let all other tools pass through
# VS Code Copilot uses "runTerminalCommand" for shell execution
case "$TOOL_NAME" in
    runTerminalCommand|runCommand|terminal|shellExecution)
        ;;
    *)
        # Not a shell command tool — allow silently
        exit 0
        ;;
esac

# Extract the command string
COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // .input // ""' 2>/dev/null | head -c 500)

if [ -z "$COMMAND" ]; then
    exit 0  # No command to check
fi

# Dangerous command patterns (require approval)
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

# Prompt user for approval via native OS dialog
ask_dialog() {
    local cmd="$1"
    local truncated="${cmd:0:200}"

    case "$(uname -s)" in
        Darwin)
            local result
            result=$(osascript -e "
                set theCmd to \"$truncated\"
                display dialog \"Dangerous command detected:\" & return & return & theCmd buttons {\"Deny\", \"Allow\"} default button \"Deny\" with title \"Lassare Hook\" giving up after 120
            " 2>/dev/null)
            if echo "$result" | grep -q "Allow"; then
                return 0  # approved
            fi
            return 1  # denied, dismissed, or timed out
            ;;
        MINGW*|MSYS*|CYGWIN*|Windows_NT)
            local result
            result=$(powershell.exe -NoProfile -Command "
                Add-Type -AssemblyName System.Windows.Forms
                \$r = [System.Windows.Forms.MessageBox]::Show(
                    \"Dangerous command detected:\`n\`n$truncated\",
                    'Lassare Hook',
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Warning)
                Write-Output \$r
            " 2>/dev/null)
            if echo "$result" | grep -qi "yes"; then
                return 0  # approved
            fi
            return 1  # denied or error
            ;;
        *)
            if command -v zenity &>/dev/null; then
                zenity --question --title="Lassare Hook" \
                    --text="Dangerous command detected:\n\n$truncated" \
                    --ok-label="Allow" --cancel-label="Deny" \
                    --timeout=120 2>/dev/null
                return $?
            elif command -v kdialog &>/dev/null; then
                kdialog --warningyesno "Dangerous command detected:\n\n$truncated" \
                    --title "Lassare Hook" 2>/dev/null
                return $?
            fi
            return 1  # no dialog tool available, deny
            ;;
    esac
}

# Ask approval via Slack
ask_slack() {
    local cmd="$1"

    if [ ! -f "$MCP_CONFIG" ]; then
        return 1  # fail-closed
    fi

    MCP_URL=$(jq -r '.servers.lassare.url // .mcpServers.lassare.url' "$MCP_CONFIG" 2>/dev/null)
    # Try VS Code format first (input variable), fall back to direct header
    API_KEY=$(jq -r '.servers.lassare.headers.Authorization // .mcpServers.lassare.headers.Authorization' "$MCP_CONFIG" 2>/dev/null | sed 's/Bearer //')

    # If API key contains ${input:...}, try reading from env or .lassare/api-key
    if echo "$API_KEY" | grep -q '${input:'; then
        if [ -f "$PROJECT_ROOT/.lassare/api-key" ]; then
            API_KEY=$(cat "$PROJECT_ROOT/.lassare/api-key" | tr -d '[:space:]')
        else
            return 1  # Can't resolve API key, fail-closed
        fi
    fi

    if [ -z "$MCP_URL" ] || [ "$MCP_URL" = "null" ] || [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
        return 1  # fail-closed
    fi

    ACTION="run_shell_command: $cmd"
    ACTION_ESCAPED=$(printf '%s' "$ACTION" | jq -Rs '.')

    RESPONSE=$(curl -s --max-time 900 \
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
                    \"context\": \"VS Code Copilot: dangerous command detected\"
                }
            }
        }" 2>/dev/null)

    # Parse SSE response
    RESULT_LINE=$(echo "$RESPONSE" | grep '^data: ' | grep '"result"' | tail -1 | sed 's/^data: //')
    TEXT_CONTENT=$(echo "$RESULT_LINE" | jq -r '.result.content[0].text // ""' 2>/dev/null)
    APPROVED=$(echo "$TEXT_CONTENT" | jq -r '.approved // false' 2>/dev/null)

    if [ "$APPROVED" = "true" ]; then
        return 0  # approved
    fi
    return 1  # denied or error
}

# --- Main ---

# Auto-allow .lassare/ file operations (mode switching, marker cleanup, dialog toggle)
if echo "$COMMAND" | grep -qE '\.lassare/(mode\.txt|stop-asked-marker|inline-dialog\.txt|api-key)'; then
    exit 0
fi

# Auto-allow lassare scripts (mode switching, status, dialog toggle)
if echo "$COMMAND" | grep -qE '(\.github/scripts/lassare-|/\.github/scripts/lassare-)'; then
    exit 0
fi

# Non-dangerous commands: allow
if ! is_dangerous "$COMMAND"; then
    exit 0
fi

# --- Dangerous command: require approval ---

# Determine mode
if [ -f "$MODE_FILE" ]; then
    MODE=$(cat "$MODE_FILE" | tr -d '[:space:]')
else
    MODE="inline"
fi

if [ "$MODE" = "slack" ]; then
    # Slack mode: always gate via Slack
    if ask_slack "$COMMAND"; then
        echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"Approved via Slack"}}'
        exit 0
    else
        echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Denied via Slack"}}'
        exit 0
    fi
else
    # Inline mode: check dialog setting
    if [ -f "$DIALOG_FILE" ]; then
        DIALOG=$(cat "$DIALOG_FILE" | tr -d '[:space:]')
    else
        DIALOG="off"
    fi

    if [ "$DIALOG" = "on" ]; then
        # Dialog enabled: show native OS dialog
        if ask_dialog "$COMMAND"; then
            echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"Approved via dialog"}}'
            exit 0
        else
            echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Denied via dialog"}}'
            exit 0
        fi
    else
        # Dialog disabled: pass-through (user opted out via /lassare-dialog-off)
        exit 0
    fi
fi

exit 0
