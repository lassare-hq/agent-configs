# Lassare for GitHub Copilot (VS Code)

> **New to Lassare?** Start at [lassare.com](https://lassare.com) · [All supported agents](../README.md)

> **[Download this folder](https://download-directory.github.io/?url=https://github.com/lassare-hq/agent-configs/tree/main/copilot)** (zip)

Setup instructions for integrating Lassare with [GitHub Copilot](https://github.com/features/copilot) in VS Code.

> **Note:** Agent hooks require VS Code 1.109+ and are currently in Preview.

## Prerequisites

- A Lassare account ([portal.lassare.com](https://portal.lassare.com))
- Slack workspace connected (Portal → Agent Setup)
- An API key (Portal → Agent Setup)
- VS Code 1.109+ with GitHub Copilot extension
- `jq` installed (`brew install jq` on macOS, `apt install jq` on Linux)

## Setup

### 1. Create directories

```bash
mkdir -p .vscode .github/prompts .github/scripts .github/hooks .lassare
```

### 2. Add MCP config

If `.vscode/mcp.json` **does not exist**:

```bash
cp mcp.json .vscode/mcp.json
```

If `.vscode/mcp.json` **already exists**, merge the `inputs` array and `servers.lassare` entry from `mcp.json` into your existing file. Both sections are required — `inputs` defines the variable, `servers` uses it.

### 3. Save API key

```bash
echo "YOUR_API_KEY" > .lassare/api-key
```

Replace `YOUR_API_KEY` with your actual key from Portal → Agent Setup.

> **Why two places?** VS Code resolves `${input:lassare-api-key}` at runtime for the MCP connection. Hook scripts run outside VS Code and read from `.lassare/api-key` instead.

### 4. Add `.lassare/api-key` to .gitignore

Append to `.gitignore` (if not already present):

```
.lassare/api-key
```

### 5. Copy hooks

```bash
cp hooks/*.sh .github/hooks/
cp hooks/hooks.json.example .github/hooks/hooks.json
chmod +x .github/hooks/*.sh
```

**What each hook does:**
- **permission-approve.sh** — Gates dangerous shell commands (`rm -rf`, `git push --force`, `sudo`, `kill`, `npm publish`, `docker rm`, and [30+ others](hooks/permission-approve.sh)). In Slack mode: sends approval request to Slack. In inline mode with dialog ON: shows a native OS popup. Edit the pattern list in `permission-approve.sh` to customize.
- **stop-notify.sh** — In Slack mode, asks via Slack "Anything else?" before allowing Copilot to stop. If you reply with a task, the hook blocks stopping and relays it. If you say "done" or don't reply, it switches back to inline mode.
  > **Known limitation (Copilot Chat 0.37.x):** The Stop hook receives Slack replies correctly, but Copilot does not reliably continue after `decision: "block"`. The agent may stop anyway despite the hook blocking. This is a Copilot-side issue — the hook works as designed.

### 6. Copy scripts and prompt files

```bash
cp scripts/*.sh .github/scripts/
cp commands/*.prompt.md .github/prompts/
chmod +x .github/scripts/*.sh
```

### 7. Set default mode

```bash
.github/scripts/lassare-inline.sh
```

### 8. Restart VS Code and verify

Restart VS Code. Check **Settings → MCP** — you should see `lassare` listed. VS Code will prompt for your API key on first connection.

Run `/hooks` in Copilot chat to verify hooks are loaded. Try `/lassare-status` to confirm mode.

## Usage

- **`ask` tool**: Questions and clarifications
  - **Slack mode**: Sent to your Slack DM — reply from your phone
  - **Inline mode** (default): Asked directly in conversation
- **`approve` tool**: Permission requests — Slack DM with Approve/Deny buttons

Questions and approvals expire after **15 minutes** if not answered.

**Going AFK with Slack mode:** When you first run `/lassare-slack`, Copilot will ask to run a shell script. Use the **Allow** dropdown and select **"Allow All Commands in this Session"** — this ensures Copilot can run commands autonomously while you're away. Without this, Copilot will pause at every command waiting for manual approval.

**Commands:**
- `/lassare-slack` — Switch to Slack mode (questions go to Slack DM)
- `/lassare-inline` — Switch to inline mode (questions in conversation)
- `/lassare-status` — Show current mode and settings
- `/lassare-dialog-on` — Enable native OS dialog for dangerous commands (inline mode)
- `/lassare-dialog-off` — Disable native OS dialog

## Optional: Instructions Snippet

Add Lassare instructions to your `.github/copilot-instructions.md` so they persist across context compressions:

If `.github/copilot-instructions.md` **does not exist**:

```bash
cp copilot-instructions-snippet.md .github/copilot-instructions.md
```

If it **already exists**, append the snippet:

```bash
cat copilot-instructions-snippet.md >> .github/copilot-instructions.md
```

## Compatibility

- Requires VS Code 1.109+ (for MCP, hooks, and prompt files)

## Troubleshooting

**MCP error "Variable must be defined in an inputs section":**
- Your `.vscode/mcp.json` is missing the `inputs` array. Copy from `mcp.json` — both `inputs` and `servers` sections are required.

**MCP OAuth dialog appears:**
- Ensure `type` is `"sse"` (not `"http"`) in `.vscode/mcp.json`. HTTP transport triggers OAuth which is incompatible with Bearer token auth.

**MCP not connecting:**
- Check **Settings → MCP** — `lassare` should be listed
- VS Code will prompt for your API key on first connection

**Slack messages not arriving:**
- Check Slack is connected in Portal → Agent Setup
- Ensure you're in Slack mode: `/lassare-status`

**Hooks not loading:**
- Run `/hooks` in Copilot chat to check loaded hooks
- Verify `.github/hooks/hooks.json` is valid JSON
- Check file permissions: `chmod +x .github/hooks/*.sh`

**Hooks can't reach Slack:**
- Ensure `.lassare/api-key` exists with your API key
- Hooks run outside VS Code and can't access `${input:...}` variables

**Hook not catching commands:**
- The hook only gates `runTerminalCommand` tool calls
- If Copilot uses a different tool name, check Diagnostics and update the `case` statement in `permission-approve.sh`

**Prompt files not appearing as slash commands:**
- Ensure files are in `.github/prompts/` with `.prompt.md` extension
- Restart VS Code after adding new prompt files

## Files

- `mcp.json` — MCP server configuration (VS Code format with input variables)
- `commands/*.prompt.md` — Prompt files / slash commands (mode switching, status, dialog toggle)
- `scripts/*.sh` — Mode switching and dialog toggle scripts (called by commands)
- `hooks/permission-approve.sh` — Dangerous command gate (Slack approval or OS dialog)
- `hooks/stop-notify.sh` — Stop hook (asks via Slack before stopping)
- `hooks/hooks.json.example` — Hook config (copy to `.github/hooks/hooks.json`)
- `copilot-instructions-snippet.md` — Instructions snippet (optional, for `.github/copilot-instructions.md`)
