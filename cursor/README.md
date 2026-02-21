# Lassare for Cursor

> **New to Lassare?** Start at [lassare.com](https://lassare.com) · [All supported agents](../README.md)

> **[Download this folder](https://download-directory.github.io/?url=https://github.com/lassare-hq/agent-configs/tree/main/cursor)** (zip)

Setup instructions for integrating Lassare with [Cursor](https://cursor.sh).

## Prerequisites

- A Lassare account ([portal.lassare.com](https://portal.lassare.com))
- Slack workspace connected (Portal → Agent Setup)
- An API key (Portal → Agent Setup)
- Cursor installed

## Setup

### 1. Create directories

```bash
mkdir -p .cursor/commands .cursor/scripts .lassare
```

### 2. Add MCP config

If `.cursor/mcp.json` **does not exist**:

```bash
cp mcp.json .cursor/mcp.json
```

If `.cursor/mcp.json` **already exists**, manually add the `lassare` entry from `mcp.json` into your existing file's `mcpServers` section.

Then replace `YOUR_API_KEY` with your API key.

### 3. Copy commands and scripts

```bash
cp commands/*.md .cursor/commands/
cp scripts/*.sh .cursor/scripts/
chmod +x .cursor/scripts/*.sh
```

### 4. Set default mode

```bash
.cursor/scripts/lassare-inline.sh
```

### 5. Restart Cursor and verify

Restart Cursor, then check **Settings → MCP** — you should see `lassare` listed as connected. Try `/lassare-status` to confirm mode.

## Usage

- **`ask` tool**: Questions and clarifications
  - **Slack mode**: Sent to your Slack DM — reply from your phone
  - **Inline mode** (default): Asked directly in conversation
- **`approve` tool**: Permission requests — Slack DM with Approve/Deny buttons

Questions and approvals expire after **15 minutes** if not answered.

Toggle with `/lassare-slack` or `/lassare-inline`.

Switching modes requires **manual** Cursor Agent settings changes:

- **Slack mode**: Set **Auto-Run Mode** = *Auto-Run in Sandbox* and **Auto-Run Network Access** = *Allow All* (Cursor Settings → Agent). The permission hook gates dangerous commands via Slack approval.
- **Inline mode**: Set **Auto-Run Mode** to *Ask every time* for manual approval prompts, or keep Sandbox mode and use the network/tool toggles.

> **Why manual?** Cursor replaced YOLO mode with Sandbox mode (Feb 2025). Unlike the old `cursor.agent.yoloMode` setting, there is currently no file or API to toggle Sandbox programmatically. The commands remind you which settings to change, and the inline dialog acts as a safety net.

### Inline dialog (dangerous command gate)

When in inline mode, the permission hook shows a native OS dialog (macOS/Windows/Linux) for dangerous commands like `rm -rf`, `git push --force`, `sudo`, etc. This is **ON by default** — so even if you forget to switch Cursor back to *Ask every time*, dangerous commands still get caught.

- `/lassare-dialog-on` — Enable OS dialog (default)
- `/lassare-dialog-off` — Disable OS dialog (dangerous commands pass through)

## Optional: Hooks (Recommended for Slack Mode)

**Why hooks matter:** Without hooks, when Cursor needs permission for a command, it blocks in your terminal waiting for you to click "Allow". If you're AFK, the agent is stuck. Sandbox mode auto-runs commands in an isolated environment, but some operations (force push, rm -rf, sudo) should still require explicit approval.

Hooks route dangerous commands to Slack instead, so you can approve from your phone without giving the agent blanket permission.

### 1. Copy hook files

```bash
mkdir -p .cursor/hooks
cp hooks/*.sh .cursor/hooks/
chmod +x .cursor/hooks/*.sh
```

### 2. Add hook config

If `.cursor/hooks.json` **does not exist**:

```bash
cp hooks/hooks.json.example .cursor/hooks.json
```

If it **already exists**, manually merge the `beforeShellExecution` and `stop` hook entries.

### 3. Verify hooks

Check file permissions: `chmod +x .cursor/hooks/*.sh .cursor/scripts/*.sh`

Verify `.cursor/hooks.json` is valid JSON.

**What each hook does:**
- **permission-approve.sh** — Gates dangerous shell commands. In Slack mode, sends approval request to Slack. In inline mode, shows a native OS dialog for approval (on by default; toggle with `/lassare-dialog-on` and `/lassare-dialog-off`). Dangerous patterns include: `rm -rf`, `git push --force`, `sudo`, `kill`, `npm publish`, `docker rm`, and [30+ others](hooks/permission-approve.sh).
- **stop-notify.sh** — When in Slack mode, asks via Slack "Anything else?" before allowing Cursor to stop. If you reply with a task, the agent continues. If you say "done" or don't reply, it switches back to inline mode.

Both hooks use `BASH_SOURCE` for path resolution, so they work correctly regardless of Cursor's working directory.

## Optional: .cursorrules Snippet

Add Lassare instructions to your `.cursorrules` so they persist across context compressions:

If `.cursorrules` **does not exist**:

```bash
cp lassare-rules.txt .cursorrules
```

If it **already exists**, append the snippet:

```bash
cat lassare-rules.txt >> .cursorrules
```

## Compatibility

- Hooks require Cursor with hooks support
- MCP tools work with any Cursor version that supports MCP

## Troubleshooting

**MCP not connecting:**
- Check **Settings → MCP** — `lassare` should be listed
- Verify your API key in `.cursor/mcp.json`

**Slack messages not arriving:**
- Check Slack is connected in Portal → Agent Setup
- Ensure you're in Slack mode: `/lassare-status`

**Approvals timing out:**
- Questions and approvals expire after 15 minutes
- Check your Slack notifications are enabled

**Hooks not working:**
- Check file permissions: `chmod +x .cursor/hooks/*.sh .cursor/scripts/*.sh`
- Verify `.cursor/hooks.json` is valid JSON
- Ensure `jq` is installed (`brew install jq` on macOS)

**Agent not auto-running commands:**
- Check Cursor Settings → Agent: **Auto-Run Mode** should be *Auto-Run in Sandbox* and **Auto-Run Network Access** should be *Allow All*
- Check `/lassare-status` to see current mode

**Script "Operation not permitted":**
- Cursor's sandbox may block shell scripts from writing to `.vscode/`. This is expected — the agent edits the file directly instead. The command files handle this split.

## Files

- `mcp.json` — MCP server configuration
- `commands/*.md` — Slash commands (mode switching, status, dialog toggle)
- `scripts/*.sh` — Mode switching and dialog toggle scripts (called by commands)
- `hooks/permission-approve.sh` — Dangerous command gate (Slack approval or OS dialog)
- `hooks/stop-notify.sh` — Stop hook (asks via Slack before stopping)
- `hooks/hooks.json.example` — Hook config (copy to `.cursor/hooks.json`)
- `lassare-rules.txt` — .cursorrules snippet (optional, recommended)
