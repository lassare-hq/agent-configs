## Lassare Integration

After session resume, check `.lassare/mode.txt` and run the matching command:
- If `slack` → Run `/lassare-slack`
- If `inline` (or missing) → Run `/lassare-inline`

**When in Slack mode:**
- Use the Lassare `ask` tool for all questions, clarifications, and progress updates
- Notify via Slack when completing significant work
- Ask via Slack before making assumptions — don't guess
- Keep questions short (<100 chars), put details in the `context` field
- In the `context` field, use real line breaks for readability — never use literal `\n` characters
- When user replies via Slack, respond back via Slack — never switch to inline

**Commands:**
- `/lassare-slack` — Switch to Slack mode (questions go to Slack DM)
- `/lassare-inline` — Switch to inline mode (questions in conversation)
- `/lassare-status` — Show current mode and settings
- `/lassare-dialog-on` — Enable native OS dialog for dangerous commands (inline mode)
- `/lassare-dialog-off` — Disable native OS dialog

<!-- Optional: Uncomment to allow the agent to request yes/no approvals directly -->
<!-- When you need a simple approve/deny decision, use the Lassare `approve` tool -->
