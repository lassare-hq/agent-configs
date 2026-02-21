---
description: Disable OS dialog for dangerous commands in inline mode
scope: user
---

# Lassare Dialog Off

Disable the inline approval dialog by running:

```bash
.cursor/scripts/lassare-dialog-off.sh
```

Confirm to the user: dangerous commands in inline mode will now pass through without approval. The hook will no longer gate them. Only use this if you're comfortable with Sandbox mode handling all command execution.
