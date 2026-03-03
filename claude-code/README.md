# Lassare for Claude Code

> **New to Lassare?** Start at [lassare.com](https://lassare.com) · [All supported agents](../README.md)

> **[Download this folder](https://download-directory.github.io/?url=https://github.com/lassare-hq/agent-configs/tree/main/claude-code)** (zip)

Setup instructions for integrating Lassare with [Claude Code](https://claude.ai/claude-code).

## Prerequisites

- A Lassare account ([portal.lassare.com](https://portal.lassare.com))
- Slack workspace connected (Portal → Agent Setup)
- An API key (Portal → Agent Setup)
- Claude Code installed

## Setup

### 1. Create directories

```bash
mkdir -p .claude/commands .claude/scripts .lassare
```

### 2. Add MCP config

If `.mcp.json` **does not exist** in your project:

```bash
cp mcp.json .mcp.json
```

If `.mcp.json` **already exists**, manually add the `lassare` entry from `mcp.json` into your existing file's `mcpServers` section.

Then replace `YOUR_API_KEY` with your API key.

### 3. Copy commands and scripts

```bash
cp commands/*.md .claude/commands/
cp scripts/*.sh .claude/scripts/
chmod +x .claude/scripts/*.sh
```

### 4. Copy hooks

```bash
mkdir -p .claude/hooks
cp hooks/*.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
```

If `.claude/settings.json` **does not exist**:

```bash
cp hooks/settings.json .claude/settings.json
```

If it **already exists**, manually merge the `hooks` section from `hooks/settings.json` into your existing file.

**What each hook does:**
- **permission-approve.sh** — Routes tool permission requests to Slack (Approve/Deny buttons). Edit the pattern list in `permission-approve.sh` to customize which commands require approval.
- **stop-notify.sh** — Asks via Slack before Claude stops ("Anything else?")
- **session-start.sh** — Reminds Claude to use Slack mode on session start

### 5. Set default mode

```bash
.claude/scripts/lassare-inline.sh
```

### 6. Restart Claude Code and verify

Restart Claude Code, then run:

```
/mcp
```

You should see `lassare` listed as a connected MCP server. Run `/hooks` to verify hooks are loaded. Try `/lassare-status` to confirm mode.

## Usage

- **`ask` tool**: Questions and clarifications
  - **Slack mode**: Sent to your Slack DM — reply from your phone
  - **Inline mode** (default): Asked directly in conversation
- **`approve` tool**: Permission requests — Slack DM with Approve/Deny buttons

Questions and approvals expire after **15 minutes** if not answered.

Toggle with `/lassare-slack` or `/lassare-inline`.

## Optional: CLAUDE.md Snippet

Add Lassare instructions to your project's `CLAUDE.md` so they persist across context compressions:

If `CLAUDE.md` **does not exist**:

```bash
cp claude-md-snippet.md CLAUDE.md
```

If it **already exists**, append the snippet:

```bash
cat claude-md-snippet.md >> CLAUDE.md
```

## Compatibility

- Hooks require Claude Code with hooks support
- MCP tools work with any Claude Code version that supports MCP

## Troubleshooting

**MCP not connecting:**
- Run `/mcp` — check that `lassare` is listed
- Verify your API key in `.mcp.json`

**Slack messages not arriving:**
- Check Slack is connected in Portal → Agent Setup
- Ensure you're in Slack mode: `/lassare-status`

**Approvals timing out:**
- Questions and approvals expire after 15 minutes
- Check your Slack notifications are enabled

**Hooks not working:**
- Run `/hooks` to verify they're registered
- Check file permissions: `chmod +x .claude/hooks/*.sh`

## Files

- `mcp.json` — MCP server configuration
- `commands/*.md` — Slash commands
- `scripts/*.sh` — Mode switching scripts (called by commands)
- `hooks/permission-approve.sh` — Permission hook
- `hooks/stop-notify.sh` — Stop hook
- `hooks/session-start.sh` — Session start hook
- `hooks/settings.json` — Hook config
- `claude-md-snippet.md` — CLAUDE.md snippet (optional, recommended)
