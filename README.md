# Lassare Agent Prompts

Setup prompts and configuration files for integrating [Lassare](https://lassare.com) with AI coding agents.

Lassare enables human-in-the-loop workflows for AI agents. When your coding agent needs to ask you a question or get approval for a risky action, it sends a message to your Slack DM — so you can respond from your phone while AFK.

## Supported Agents

### Tested & Documented

- **[Claude Code](./claude-code/)** — MCP config, slash commands, hooks
- **[Cursor](./cursor/)** — MCP config, slash commands, hooks
- **[Gemini CLI](./gemini/)** — MCP config, slash commands, hooks

### Other MCP Clients

Lassare works with any MCP-compatible agent. Use the [generic config](./other/) as a starting point — includes MCP setup and guidance for implementing mode switching.

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
│ (ask / approve)│     │   (MCP)     │     │ (DM/mobile) │
└────────────────┘     └─────────────┘     └─────────────┘
                              │
                              ▼
                       ┌─────────────┐
                       │ You respond │
                       │ (from phone)│
                       └─────────────┘
```

**Two tools:**
1. **`ask`** — Agent needs clarification → you get a Slack DM → reply with your answer
2. **`approve`** — Agent needs permission for a risky action → you get Approve/Deny buttons in Slack

Questions and approvals expire after **15 minutes** if not answered.

## Modes

- **Inline mode** (default): Questions asked directly in the conversation — for when you're at your desk
- **Slack mode**: Questions go to your Slack DM — respond from your phone while AFK

Toggle with `/lassare-slack` or `/lassare-inline` commands.

## Contributing

We welcome contributions! See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

**Ways to contribute:**
- Add support for new agents
- Improve prompts for better agent behavior
- Fix bugs or typos
- Add examples and use cases

## Links

- [Portal](https://portal.lassare.com) - Get your API key
- [Feedback & Issues](https://github.com/lassare-hq/agent-configs/issues)

## License

MIT License - see [LICENSE](./LICENSE)
