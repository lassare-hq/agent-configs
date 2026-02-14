---
description: Switch to Slack mode - questions sent to your Slack DM
scope: user
---

# Lassare Slack Mode

```bash
mkdir -p .lassare && echo "slack" > .lassare/mode.txt && rm -f .lassare/stop-asked-marker
echo "Switched to SLACK mode"
```

## ⚠️ STRICT ADHERENCE REQUIRED

When in Slack mode, you **MUST** use the `ask` MCP tool for ALL communication:

**✅ ALWAYS use Slack for:**
- ANY question, clarification, or confirmation needed
- Task completion notifications (brief recap + "What's next?")
- Before making assumptions about unclear requirements
- Significant decisions (architecture, approach, scope)
- When you're unsure about anything

**❌ NEVER do these in Slack mode:**
- Ask questions inline in the conversation
- Respond with inline text after receiving a Slack reply
- Assume the answer without asking
- Skip notification when completing significant work
- Wait until you're blocked - ask proactively

**🔄 IMPORTANT: Keep the conversation in Slack**
When user replies via Slack, you MUST respond back via the `ask` MCP tool - never switch to inline text. The user is on their phone, keep the conversation there.

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
