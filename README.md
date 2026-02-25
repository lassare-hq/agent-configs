# Lassare — Control Claude Code, Cursor & Gemini CLI Remotely

> Your AI coding agent keeps running. When it needs your input, Lassare sends the question to Slack. You answer from your phone. The agent continues.

Lassare is an [MCP server](https://modelcontextprotocol.io/) that lets you respond to AI coding agent questions remotely via Slack — so you don't have to stay at your desk while your agent works.

## Supported Agents

### Tested & Documented

- **[Claude Code](./claude-code/)** — MCP config, slash commands, hooks
- **[Cursor](./cursor/)** — MCP config, slash commands, hooks
- **[Gemini CLI](./gemini/)** — MCP config, slash commands, hooks

### Other MCP Clients

Lassare works with any MCP-compatible agent (Windsurf, GitHub Copilot, Continue, Aider, and more). Use the [generic config](./other/) as a starting point.

**Using a different agent?** [Let us know](https://github.com/lassare-hq/agent-configs/issues) what works or what you'd like us to support next.

## Quick Start

1. **Sign up** at [portal.lassare.com](https://portal.lassare.com) and connect your Slack workspace
2. **Get your API key** from Agent Setup
3. **Choose your agent** from the folders above
4. **Follow the README** in that folder

## How It Works

```
┌────────────────┐     ┌─────────────┐     ┌─────────────┐
│  Your Agent    │────▶│   Lassare   │────▶│ Your Slack  │
│ (ask / approve)│◀────│   (MCP)     │◀────│ (DM/mobile) │
└────────────────┘     └─────────────┘     └─────────────┘
  agent continues       relays answer        you respond
```

**Two tools:**
1. **`ask`** — Agent needs clarification → you get a Slack DM → reply with your answer
2. **`approve`** — Agent needs permission for a risky action → you get Approve/Deny buttons in Slack

Questions and approvals expire after **15 minutes** if not answered.

## Common Questions

**How do I control Claude Code remotely?**
Add Lassare as an MCP server in your `.mcp.json`. When Claude Code needs input, it calls the `ask` tool — the question arrives on Slack, you respond from your phone, Claude Code continues.

**Can I answer Cursor questions from my phone?**
Yes. Configure Lassare in Cursor's MCP settings. When the agent hits a decision point, you get a Slack notification and reply from anywhere.

**Does Gemini CLI work with Lassare?**
Yes. Gemini CLI supports MCP servers. Add Lassare to your settings and agent questions arrive via Slack.

**Can I use my AI coding agent while AFK?**
That's exactly what Lassare is for. Your agent keeps running wherever it's running — you just answer questions remotely via Slack when it needs your input.

**Is my code sent to Lassare?**
No. Lassare only sees the questions your agent sends. Your code stays on your machine.

## Modes

- **Inline mode** (default): Questions asked directly in the conversation — for when you're at your desk
- **Slack mode**: Questions go to your Slack DM — respond from your phone while AFK

Toggle with `/lassare-slack` or `/lassare-inline` commands.

## Pricing

- **Free**: 200 questions/month, no credit card required
- **Solo**: $9/month for 2,000 questions/month

## Contributing

We welcome contributions! See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

**Ways to contribute:**
- Add support for new agents
- Improve prompts for better agent behavior
- Fix bugs or typos
- Add examples and use cases

## Links

- [Website](https://lassare.com) — How it works, setup guide, and pricing
- [Portal](https://portal.lassare.com) — Get your API key
- [Status](https://status.lassare.com) — Service status and uptime
- [Feedback & Issues](https://github.com/lassare-hq/agent-configs/issues)
- [support@lassare.com](mailto:support@lassare.com) — Support

## License

MIT License - see [LICENSE](./LICENSE)
