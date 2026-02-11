# Contributing to Lassare Agent Prompts

Thank you for your interest in contributing! This repo contains setup prompts and configurations for integrating Lassare with various AI coding agents.

## How to Contribute

### Adding Support for a New Agent

1. **Create a folder** with the agent name (lowercase, hyphenated)
2. **Add a README.md** with setup instructions
3. **Include the configuration files** specific to that agent
4. **Test the integration** to ensure it works
5. **Submit a PR** with your changes

### Improving Existing Prompts

The prompts in this repo tell agents how to use the Lassare `ask` tool effectively. Good prompts should:

- Be concise but clear
- Explain when to use Slack mode vs inline mode
- Include the `/lassare-slack` toggle command
- Follow the agent's conventions (e.g., markdown for Claude, plaintext for Cursor)

### Folder Structure

Each agent folder should contain:

```
agent-name/
├── README.md           # Setup instructions
├── [config-file]       # Agent-specific config (CLAUDE.md, .cursorrules, etc.)
├── commands/           # Slash commands (if supported)
│   ├── lassare-slack.md
│   └── lassare-status.md
└── [scripts]           # Shell scripts (if needed)
```

## Testing Your Changes

Before submitting a PR:

1. **Test the MCP connection** - Ensure your config connects to Lassare
2. **Test the ask tool** - Verify questions are sent to Slack
3. **Test mode toggle** - Confirm `/lassare-slack` switches modes
4. **Test inline mode** - Verify `LASSARE_INLINE_MODE=true` works

## Code of Conduct

- Be respectful and constructive
- Focus on improving the developer experience
- Help newcomers get started

## Questions?

- Open an issue in [lassare-hq/feedback](https://github.com/lassare-hq/feedback)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
