#!/bin/bash
# Permission Request hook: Gate dangerous commands via Slack or OS dialog
#
# Strategy:
# 1. Auto-allow safe operations (.lassare/, ask tool, non-shell tools)
# 2. Auto-allow commands in user's autoApprove list
# 3. Allow non-dangerous shell commands
# 4. For dangerous commands:
#    - Slack mode: request approval via Slack buttons
#    - Inline mode + dialog ON: show native OS dialog (macOS/Windows/Linux)
#    - Inline mode + dialog OFF (default): pass-through, let Gemini handle it
# 5. Fail-closed: any error in Slack mode → deny dangerous commands
#
# Config files:
#   .lassare/mode.txt           - "slack" or "inline" (default: inline)
#   .lassare/inline-dialog.txt  - "on" or "off" (default: off)
#
# Gemini hook format: Receives JSON via stdin, returns JSON via stdout
# Output: {"decision": "allow"} or {"decision": "deny", "reason": "..."}

MODE_FILE=".lassare/mode.txt"
DIALOG_FILE=".lassare/inline-dialog.txt"
SETTINGS_FILE=".gemini/settings.json"

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

# Prompt user for approval via native OS dialog
ask_dialog() {
    local cmd="$1"
    local truncated="${cmd:0:200}"

    case "$(uname -s)" in
        Darwin)
            # macOS: native dialog via osascript
            local result
            result=$(osascript -e "
                set theCmd to \"$truncated\"
                display dialog \"⚠️ Dangerous command detected:\" & return & return & theCmd buttons {\"Deny\", \"Allow\"} default button \"Deny\" with title \"Lassare Hook\" giving up after 120
            " 2>/dev/null)
            if echo "$result" | grep -q "Allow"; then
                return 0  # approved
            fi
            return 1  # denied, dismissed, or timed out
            ;;
        MINGW*|MSYS*|CYGWIN*|Windows_NT)
            # Windows: PowerShell message box
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
            # Linux/other: try zenity, kdialog, or fall back to deny
            if command -v zenity &>/dev/null; then
                zenity --question --title="Lassare Hook" \
                    --text="⚠️ Dangerous command detected:\n\n$truncated" \
                    --ok-label="Allow" --cancel-label="Deny" \
                    --timeout=120 2>/dev/null
                return $?
            elif command -v kdialog &>/dev/null; then
                kdialog --warningyesno "⚠️ Dangerous command detected:\n\n$truncated" \
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

    # Get MCP URL and API key from settings.json
    if [ ! -f "$SETTINGS_FILE" ]; then
        return 1  # fail-closed
    fi

    MCP_URL=$(jq -r '.mcpServers.lassare.httpUrl // .mcpServers.lassare.url' "$SETTINGS_FILE" 2>/dev/null)
    API_KEY=$(jq -r '.mcpServers.lassare.headers.Authorization' "$SETTINGS_FILE" 2>/dev/null | sed 's/Bearer //')

    if [ -z "$MCP_URL" ] || [ "$MCP_URL" = "null" ] || [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
        return 1  # fail-closed
    fi

    # Build action description
    ACTION="run_shell_command: $cmd"
    ACTION_ESCAPED=$(printf '%s' "$ACTION" | jq -Rs '.')

    # Call approve tool via Slack
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
                    \"context\": \"Gemini CLI: dangerous command detected\"
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

# Read hook input first (Gemini sends JSON via stdin)
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"' 2>/dev/null || echo "unknown")
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // .tool_input.file_path // "action"' 2>/dev/null | head -c 500 || echo "action")

# Auto-allow .lassare/ file operations (mode switching, marker cleanup, dialog toggle)
if echo "$COMMAND" | grep -qE '\.lassare/(mode\.txt|stop-asked-marker|inline-dialog\.txt)'; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Auto-allow lassare scripts (mode switching, status, dialog toggle)
if echo "$COMMAND" | grep -qE '(\.gemini/scripts/lassare-|/\.gemini/scripts/lassare-)'; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Always allow 'ask' and 'approve' tools without approval
if [ "$TOOL_NAME" = "ask" ] || [ "$TOOL_NAME" = "approve" ]; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Only gate shell commands for now
if [ "$TOOL_NAME" != "run_shell_command" ]; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Check if user explicitly trusts this command
if is_auto_approved "$COMMAND"; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Non-dangerous commands: allow
if ! is_dangerous "$COMMAND"; then
    echo '{"decision": "allow"}'
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
        echo '{"decision": "allow"}'
    else
        echo '{"decision": "deny", "reason": "Denied via Slack (or approval failed)"}'
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
            echo '{"decision": "allow"}'
        else
            echo '{"decision": "deny", "reason": "Denied by user (or dialog timed out)"}'
        fi
    else
        # Dialog disabled: pass-through, let Gemini handle approval
        echo '{"decision": "allow"}'
    fi
fi

exit 0
