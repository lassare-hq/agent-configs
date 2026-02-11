# Contributing to Lassare Agent Configs

Thank you for your interest in contributing! This repo contains setup configs and prompts for integrating Lassare with AI coding agents.

## How to Contribute

### Adding Support for a New Agent

1. **Create a folder** with the agent name (lowercase, hyphenated)
2. **Add a README.md** with setup instructions (see existing agents for structure)
3. **Include configuration files** specific to that agent
4. **Test the integration** to ensure it works
5. **Submit a PR** with your changes

### Improving Existing Configs

Good configs should:

- Be concise but clear
- Explain when to use Slack mode vs inline mode
- Include the `/lassare-slack` toggle command
- Follow the agent's conventions (e.g., markdown for Claude, TOML for Gemini)
- Include a persistent instructions snippet (for surviving context compressions)

### Folder Structure

Each agent folder should contain:

```
agent-name/
├── README.md              # Setup instructions
├── mcp.json               # MCP server configuration
├── [snippet-file]         # Persistent instructions (e.g., claude-md-snippet.md)
├── commands/              # Slash commands (if supported)
│   ├── lassare-slack.*
│   ├── lassare-inline.*
│   └── lassare-status.*
└── hooks/                 # Hook scripts (if supported)
    ├── permission-approve.sh
    └── stop-notify.sh
```

## Testing Your Changes

Before submitting a PR:

1. **Test the MCP connection** — Ensure your config connects to Lassare
2. **Test the ask tool** — Verify questions are sent to Slack in Slack mode
3. **Test mode toggle** — Confirm `/lassare-slack` and `/lassare-inline` switch modes
4. **Test inline mode** — Verify questions are asked directly in conversation

## Code of Conduct

- Be respectful and constructive
- Focus on improving the developer experience
- Help newcomers get started

## Questions?

- Open an issue on [this repo](https://github.com/lassare-hq/agent-configs/issues)
- Join the [community discussions](https://github.com/lassare-hq/docs/discussions)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
