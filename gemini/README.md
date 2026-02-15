# Lassare for Gemini CLI

> **New to Lassare?** Start at [lassare.com](https://lassare.com) · [All supported agents](../README.md)

> **[Download this folder](https://download-directory.github.io/?url=https://github.com/lassare-hq/agent-configs/tree/main/gemini)** (zip)

Setup instructions for integrating Lassare with [Gemini CLI](https://github.com/google-gemini/gemini-cli).

## Prerequisites

- A Lassare account ([portal.lassare.com](https://portal.lassare.com))
- Slack workspace connected (Portal → Agent Setup)
- An API key (Portal → Agent Setup)
- Gemini CLI installed

## Setup

### 1. Create directories

```bash
mkdir -p .gemini/commands .gemini/scripts .lassare
```

### 2. Add MCP config

If `.gemini/settings.json` **does not exist**:

```bash
cp mcp.json .gemini/settings.json
```

If `.gemini/settings.json` **already exists**, manually add the `lassare` entry from `mcp.json` into your existing file's `mcpServers` section.

Then replace `YOUR_API_KEY` with your API key.

### 3. Copy commands and scripts

```bash
cp commands/*.toml .gemini/commands/
cp scripts/*.sh .gemini/scripts/
chmod +x .gemini/scripts/*.sh
```

### 4. Set default mode

```bash
echo "inline" > .lassare/mode.txt
```

### 5. Restart Gemini CLI and verify

Restart Gemini CLI. Try `/lassare-status` to confirm mode.

## Usage

### Modes

| Mode | Questions | Dangerous Commands | Safe Commands |
|------|-----------|-------------------|---------------|
| **Slack** | via Slack DM | Slack approval required | auto-approved |
| **Inline** (default) | in conversation | Gemini CLI prompts | Gemini CLI prompts |

Questions and approvals expire after **15 minutes** if not answered.

### Commands

| Command | Description |
|---------|-------------|
| `/lassare-slack` | Switch to Slack mode |
| `/lassare-inline` | Switch to inline mode |
| `/lassare-status` | Show current mode and settings |
| `/lassare-dialog-on` | Enable OS dialog for dangerous commands (inline mode) |
| `/lassare-dialog-off` | Disable OS dialog |

### YOLO mode

| Mode | YOLO | Behavior |
|------|------|----------|
| Slack | ON (recommended) | Hook gates dangerous commands via Slack, safe commands auto-approve |
| Slack | OFF | Double prompting (Gemini native + Slack) — works but annoying |
| Inline | OFF (recommended) | Gemini CLI prompts for dangerous commands |
| Inline + dialog ON | ON or OFF | Hook shows OS popup for dangerous commands |
| Inline + dialog OFF | ON | **No safety net** — dangerous commands run without any approval |

## Optional: Hooks (Recommended for Slack Mode)

**Why hooks matter:** Without hooks, when Gemini CLI needs permission for a command, it blocks at your terminal for approval. If you're AFK, the agent is stuck. The only alternative is YOLO mode, which auto-approves everything — risky.

Hooks route dangerous commands to Slack for approval, while safe commands pass through automatically.

**Requirement:** Hooks require Gemini CLI Preview/Nightly channel, or explicit enablement on Stable.

### 1. Copy hook files

```bash
mkdir -p .gemini/hooks
cp hooks/*.sh .gemini/hooks/
chmod +x .gemini/hooks/*.sh
```

### 2. Merge hook config into `.gemini/settings.json`

Add the following to your existing `.gemini/settings.json`:

```json
{
  "approvalMode": "default",
  "experiments": {
    "hooksEnabled": true
  },
  "hooksConfig": {
    "enabled": true
  },
  "hooks": {
    "BeforeTool": [
      {
        "enabled": true,
        "matcher": "*",
        "hooks": [
          {
            "name": "lassare-permission",
            "type": "command",
            "command": "$GEMINI_PROJECT_DIR/.gemini/hooks/permission-approve.sh",
            "timeout": 900000,
            "description": "Request approval via Slack for shell commands"
          }
        ]
      }
    ],
    "AfterAgent": [
      {
        "enabled": true,
        "hooks": [
          {
            "name": "lassare-stop-notify",
            "type": "command",
            "command": "$GEMINI_PROJECT_DIR/.gemini/hooks/stop-notify.sh",
            "timeout": 900000,
            "description": "Ask user via Slack before stopping (Slack mode only)"
          }
        ]
      }
    ]
  }
}
```

### 3. Verify hooks

```
/hooks panel
```

### How hooks work

**Permission hook (BeforeTool):**
1. Auto-allows lassare scripts, `.lassare/` file operations, and MCP tools
2. Checks dangerous command patterns against a built-in list
3. In Slack mode: gates dangerous commands via Slack approval buttons
4. In inline mode + dialog ON: shows native OS popup (macOS/Windows/Linux)
5. In inline mode + dialog OFF: passes through, lets Gemini handle it
6. Fail-closed in Slack mode: errors deny dangerous commands

**Stop hook (AfterAgent):**
1. Only active in Slack mode (exits immediately in inline mode)
2. Asks "Anything else?" via Slack when Gemini is about to stop
3. User can reply with a new task (agent continues) or say "done" (agent stops)
4. On timeout/no response: allows stop, switches to inline mode

### Dangerous commands (blocked in Slack mode)

- `rm -rf`, `rm -r`, `rmdir`
- `git push --force`, `git reset --hard`, `git clean -fd`
- `sudo`, `chmod 777`, `chmod -R`, `chown -R`
- `curl|bash`, `wget|bash`
- `docker rm`, `kubectl delete`
- See `hooks/permission-approve.sh` for full list

**Override**: Add trusted commands to `tools.shell.autoApprove`:

```json
{
  "tools": {
    "shell": {
      "autoApprove": ["git ", "npm test", "pytest"]
    }
  }
}
```

### Inline dialog (OS popup)

For an extra safety net in inline mode, enable the OS dialog:

```
/lassare-dialog-on
```

This shows a native popup for dangerous commands, even with YOLO mode on. Disable with `/lassare-dialog-off`.

Supported platforms: macOS (osascript, tested), Windows (PowerShell, untested), Linux (zenity/kdialog, untested).

## Optional: GEMINI.md Snippet

Add Lassare instructions to your project's `GEMINI.md` so they persist across context compressions:

If `GEMINI.md` **does not exist**:

```bash
cp gemini-md-snippet.md GEMINI.md
```

If it **already exists**, append the snippet:

```bash
cat gemini-md-snippet.md >> GEMINI.md
```

## Known Limitations

- ANSI color codes are not rendered in Gemini CLI shell output
- `/hooks disable` cannot be toggled programmatically by the agent (security guardrail)
- "Running hook..." message appears even when hooks exit early (cosmetic)
- `tools.allowed` syntax for auto-approving specific scripts is untested

## Compatibility

- Hooks require Gemini CLI Preview/Nightly channel (or explicit enablement on Stable)
- MCP tools work with any Gemini CLI version that supports MCP

## Troubleshooting

**MCP not connecting:**
- Verify your API key in `.gemini/settings.json`
- Check the `mcpServers.lassare` section is valid JSON

**Slack messages not arriving:**
- Check Slack is connected in Portal → Agent Setup
- Ensure you're in Slack mode: `/lassare-status`

**Approvals timing out:**
- Questions and approvals expire after 15 minutes
- Check your Slack notifications are enabled

**Hooks not working:**
- Verify you're on Preview/Nightly channel (or hooks are enabled on Stable)
- Check file permissions: `chmod +x .gemini/hooks/*.sh`
- Run `/hooks panel` to verify registration

## Files

- `mcp.json` — MCP server configuration
- `commands/*.toml` — Slash commands (5 commands)
- `scripts/*.sh` — Shell scripts called by commands (5 scripts)
- `hooks/permission-approve.sh` — Permission hook (optional, recommended)
- `hooks/stop-notify.sh` — Stop notification hook (optional, recommended)
- `gemini-md-snippet.md` — GEMINI.md snippet (optional, recommended)
