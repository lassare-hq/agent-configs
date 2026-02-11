---
description: Show current Lassare Slack/inline mode
scope: user
---

# Lassare Mode Status

```bash
if [ -f ".lassare/mode.txt" ]; then
  echo "Mode: $(cat .lassare/mode.txt | tr -d '[:space:]')"
else
  echo "Mode: slack (default)"
fi
```

To change mode, run `/lassare-slack` or `/lassare-inline`.
