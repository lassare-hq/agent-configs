---
description: Switch to Slack mode - questions sent to your Slack DM
scope: user
---

# Lassare Slack Mode

```bash
.claude/scripts/lassare-slack.sh
```

## ⚠️ STRICT ADHERENCE REQUIRED

When in Slack mode, you **MUST** use `mcp__lassare__ask` for ALL communication:

**✅ ALWAYS use Slack for:**
- ANY question, clarification, or confirmation needed
- Task completion notifications (brief recap + "What's next?")
- Before making assumptions about unclear requirements
- Significant decisions (architecture, approach, scope)
- When you're unsure about anything

**❌ NEVER do these in Slack mode:**
- Use `AskUserQuestion` tool (inline questions)
- Respond with inline text after receiving a Slack reply
- Assume the answer without asking
- Skip notification when completing significant work
- Wait until you're blocked - ask proactively

**🔄 IMPORTANT: Keep the conversation in Slack**
When user replies via Slack, you MUST respond back via `mcp__lassare__ask` - never switch to inline text. The user is on their phone, keep the conversation there.

## Format

- Keep question short (<100 chars) - this is the Slack message title
- Put ALL details in `context` parameter
- In `context`, use real line breaks for readability — NEVER use literal `\n` characters
- User responds from phone, keep it scannable

## Examples

**Task completion:**
```
question: "Admin portal changes done. What's next?"
context: "Completed:
- Plan filter
- Clickable companies
- User list fix

Ready to commit."
```

**Clarification:**
```
question: "Should activity log show user email or ID?"
context: "Currently shows obfuscated email.
Could show user_id instead for better privacy."
```

**Before assuming:**
```
question: "No tests exist for this. Should I add them?"
context: "Adding plan filter to companies list.
No existing test coverage for filters."
```
