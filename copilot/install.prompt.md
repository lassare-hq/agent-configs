---
description: Install or update Lassare - remote Slack notifications for Copilot
---

# Install Lassare for GitHub Copilot

Follow these instructions step by step to install Lassare. Execute each step — do NOT edit these instructions.

This is idempotent — safe to run again to update existing installations.

**CRITICAL: Do NOT modify any downloaded files. Use them exactly as downloaded.**

## Step 1: Check existing installation

Check if Lassare is already installed by looking for `.lassare/mode.txt` or `.github/hooks/permission-approve.sh`.

If files exist, read the second line of each script for the version (format: `# lassare-config vX.Y.Z`). Report to user:
- "Lassare is already installed (vX.Y.Z). Checking for updates..."
- Or: "No existing installation found. Starting fresh install."

## Step 2: Ask user for API key

Check if `.lassare/api-key` already exists. If it does, tell the user: "API key already configured. Want to update it? (Enter new key or say 'keep existing')"

If no key exists, ask: "What is your Lassare API key? (Get one at portal.lassare.com → Agent Setup)"

If they don't have one, tell them to sign up at portal.lassare.com first.

## Step 3: Create directories

```bash
mkdir -p .vscode .github/prompts .github/scripts .github/hooks .lassare
```

## Step 4: Download files from GitHub

Download all Lassare config files. **Do NOT modify any file content.**

For each file: if the target already exists, compare the version line (`# lassare-config vX.Y.Z`). If the existing version is the same or newer, skip it. If older or missing, tell the user: "Updating [filename] from vX.Y.Z to vA.B.C" and download.

```bash
BASE_URL="https://raw.githubusercontent.com/stooj-git/lassare/main/agent-prompts/copilot"

# Scripts (mode switching, dialog toggle)
curl -sL "$BASE_URL/scripts/lassare-slack.sh" -o .github/scripts/lassare-slack.sh
curl -sL "$BASE_URL/scripts/lassare-inline.sh" -o .github/scripts/lassare-inline.sh
curl -sL "$BASE_URL/scripts/lassare-status.sh" -o .github/scripts/lassare-status.sh
curl -sL "$BASE_URL/scripts/lassare-dialog-on.sh" -o .github/scripts/lassare-dialog-on.sh
curl -sL "$BASE_URL/scripts/lassare-dialog-off.sh" -o .github/scripts/lassare-dialog-off.sh

# Prompt files (slash commands)
curl -sL "$BASE_URL/commands/lassare-slack.prompt.md" -o .github/prompts/lassare-slack.prompt.md
curl -sL "$BASE_URL/commands/lassare-inline.prompt.md" -o .github/prompts/lassare-inline.prompt.md
curl -sL "$BASE_URL/commands/lassare-status.prompt.md" -o .github/prompts/lassare-status.prompt.md
curl -sL "$BASE_URL/commands/lassare-dialog-on.prompt.md" -o .github/prompts/lassare-dialog-on.prompt.md
curl -sL "$BASE_URL/commands/lassare-dialog-off.prompt.md" -o .github/prompts/lassare-dialog-off.prompt.md

# Hook scripts (permission gating and stop notification)
curl -sL "$BASE_URL/hooks/permission-approve.sh" -o .github/hooks/permission-approve.sh
curl -sL "$BASE_URL/hooks/stop-notify.sh" -o .github/hooks/stop-notify.sh

# Instructions snippet (to temp file for merging)
curl -sL "$BASE_URL/copilot-instructions-snippet.md" -o /tmp/lassare-copilot-snippet.md

# Make scripts executable
chmod +x .github/scripts/*.sh .github/hooks/*.sh
```

Verify downloads succeeded by checking that each file is non-empty. If any download fails, tell the user which file failed and suggest checking their network connection.

## Step 5: Create or merge MCP config

Check if `.vscode/mcp.json` exists:

**If it does NOT exist**, create it:

```json
{
  "inputs": [
    {
      "type": "promptString",
      "id": "lassare-api-key",
      "description": "Lassare API key (from portal.lassare.com → Agent Setup)",
      "password": true
    }
  ],
  "servers": {
    "lassare": {
      "type": "http",
      "url": "https://mcp.lassare.com/mcp",
      "headers": {
        "Authorization": "Bearer ${input:lassare-api-key}"
      }
    }
  }
}
```

**If it ALREADY exists**, read it and check:
- If `servers.lassare` already exists → tell user "MCP server already configured, skipping"
- If `servers.lassare` does not exist → merge the `lassare` input and server entry. Do not overwrite other servers or inputs.

## Step 6: Create or merge hook config

Check if `.github/hooks/hooks.json` exists:

**If it does NOT exist**, create it:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "type": "command",
        "command": ".github/hooks/permission-approve.sh",
        "timeout": 900
      }
    ],
    "Stop": [
      {
        "type": "command",
        "command": ".github/hooks/stop-notify.sh",
        "timeout": 900
      }
    ]
  }
}
```

**If it ALREADY exists**, read it and check:
- If `hooks.PreToolUse` already contains `permission-approve.sh` → skip
- If `hooks.Stop` already contains `stop-notify.sh` → skip
- Otherwise merge the missing entries. Do not overwrite existing hooks.

## Step 7: Save API key and set default mode

If the user provided a new API key in Step 2:

```bash
echo "THE_API_KEY" > .lassare/api-key
```

If `.lassare/mode.txt` does not exist:

```bash
echo "inline" > .lassare/mode.txt
```

If it already exists, leave it unchanged (preserves current mode).

## Step 8: Update .gitignore

Check `.gitignore` and append only lines that are not already present:

```
# Lassare runtime state
.lassare/api-key
.lassare/mode.txt
.lassare/inline-dialog.txt
.lassare/stop-asked-marker
.lassare/stop-ask-lock
```

## Step 9: Add instructions snippet

Check if `.github/copilot-instructions.md` exists:

- **If it exists**: check if it already contains "Lassare Integration". If yes → tell user "Instructions already present, skipping". If no → append the contents of `/tmp/lassare-copilot-snippet.md`.
- **If it does not exist**: copy `/tmp/lassare-copilot-snippet.md` to `.github/copilot-instructions.md`.

Clean up: `rm -f /tmp/lassare-copilot-snippet.md`

## Step 10: Tell the user what to do manually

After completing all steps, summarize what was done (installed/updated/skipped) and tell the user:

> **Almost done! Manual steps:**
>
> 1. **Enable hooks** (if not already): VS Code Settings → search `chat.hooks.enabled` → set to `true`
> 2. **Restart VS Code** to load the MCP server and hooks
>
> Then try `/lassare-status` in chat to verify everything works.
>
> **Prerequisite:** `jq` must be installed (`brew install jq` on macOS, `apt install jq` on Linux) — hooks need it to parse JSON.
