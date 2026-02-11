# Lassare for Other MCP Clients

> **New to Lassare?** Start at [lassare.com](https://lassare.com) · [All supported agents](../README.md)

> **[Download this folder](https://download-directory.github.io/?url=https://github.com/lassare-hq/agent-configs/tree/main/other)** (zip)

Generic setup for any MCP-compatible AI coding agent.

## Prerequisites

- A Lassare account ([portal.lassare.com](https://portal.lassare.com))
- Slack workspace connected (Portal → Agent Setup)
- An API key (Portal → Agent Setup)
- An MCP-compatible coding agent

## Setup

### 1. Add MCP config

Add to your agent's MCP configuration:

```json
{
  "mcpServers": {
    "lassare": {
      "type": "http",
      "url": "https://mcp.lassare.com/mcp",
      "timeout": 900000,
      "headers": {
        "Authorization": "Bearer YOUR_API_KEY"
      }
    }
  }
}
```

Replace `YOUR_API_KEY` with your API key.

### 2. Create mode file

```bash
mkdir -p .lassare
echo "inline" > .lassare/mode.txt
```

### 3. Restart your agent and verify

Restart your agent and check that `lassare` appears as a connected MCP server (the exact way to check varies by agent).

## Available Tools

Once configured, your agent has access to:

- **`ask`** — Send questions to Slack (in Slack mode) or ask inline (in inline mode)
- **`approve`** — Request yes/no approval via Slack buttons

Questions and approvals expire after **15 minutes** if not answered.

## Mode Switching

| Mode | Behavior |
|------|----------|
| **inline** (default) | Questions asked directly in conversation |
| **slack** | Questions sent to your Slack DM |

### Manual switching

```bash
# Switch to Slack mode (respond from phone)
echo "slack" > .lassare/mode.txt

# Switch to inline mode (respond in terminal)
echo "inline" > .lassare/mode.txt
```

### Teaching your agent to switch modes

If your agent supports custom commands or prompts, add this to your agent's configuration:

```
## Lassare Mode Switching

When user says "/lassare-slack":
1. Run: echo "slack" > .lassare/mode.txt
2. Respond: "Switched to Slack mode. Questions will be sent to your Slack DM."

When user says "/lassare-inline":
1. Run: echo "inline" > .lassare/mode.txt
2. Respond: "Switched to inline mode. Questions will be asked here."

Always check .lassare/mode.txt before using the ask tool to know current mode.
```

### Agent-specific commands

For agents that support slash commands, see [claude-code](../claude-code/), [cursor](../cursor/), or [gemini](../gemini/) for examples.

## Optional: Instructions Snippet

Most coding agents have a persistent instructions file (e.g., `CLAUDE.md`, `.cursorrules`, `GEMINI.md`, `.windsurfrules`, `.github/copilot-instructions.md`). Adding Lassare instructions ensures they survive context compressions.

Append `instructions-snippet.md` to your agent's instructions file:

```bash
cat instructions-snippet.md >> YOUR_AGENT_INSTRUCTIONS_FILE
```

## Hooks (If Supported)

If your agent supports hooks/callbacks for tool approval, you can route permission requests through Slack instead of blocking at the terminal. This lets you approve risky actions from your phone without using YOLO mode.

See the tested agent configs for hook implementation examples.

## Troubleshooting

**MCP not connecting:**
- Verify your API key in your agent's MCP config
- Check the MCP URL: `https://mcp.lassare.com/mcp`

**Slack messages not arriving:**
- Check Slack is connected in Portal → Agent Setup
- Ensure mode is set to `slack`: check `.lassare/mode.txt`

**Approvals timing out:**
- Questions and approvals expire after 15 minutes
- Check your Slack notifications are enabled

## Contributing

Got Lassare working with a new agent? Please contribute your config! See [CONTRIBUTING.md](../CONTRIBUTING.md).

## Files

- `mcp.json` — MCP server configuration (reference)
- `instructions-snippet.md` — Agent instructions snippet (optional, recommended)
