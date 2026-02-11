## Lassare Integration

After session resume, check `.lassare/mode.txt` and run the matching command:
- If `slack` → Run `/lassare-slack`
- If `inline` (or missing) → Run `/lassare-inline`

**When in Slack mode:**
- Use the Lassare `ask` tool for all questions, clarifications, and progress updates
- Notify via Slack when completing significant work
- Ask via Slack before making assumptions — don't guess
- Keep questions short (<100 chars), put details in the `context` field
- When user replies via Slack, respond back via Slack — never switch to inline

**Commands:**
- `/lassare-slack` — Questions sent to your Slack DM
- `/lassare-inline` — Questions asked in the conversation
- `/lassare-status` — Check current mode

<!-- Optional: Uncomment to allow the agent to request yes/no approvals directly -->
<!-- When you need a simple approve/deny decision, use the Lassare `approve` tool -->
