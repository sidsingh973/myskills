---
name: sessmem
description: Browse saved sessions by topic tag and load one to resume. Replacement for /prevmem.
---

## Step 1 — List tags with latest session

```bash
for tag in $(ls ~/.claude/sessions/ 2>/dev/null | sort); do
  latest=$(ls ~/.claude/sessions/$tag/ | sort -r | head -1)
  date=$(echo $latest | cut -c1-10)
  echo "$tag — $date"
done
```

If no sessions exist, say: "No saved sessions yet. Use /savemem to save a session." and stop.

Present as a numbered list:
> Your session threads:
> 1. hec-hms — 2026-06-09
> 2. dobeypilot — 2026-06-03
> ...

Wait for the user to pick a number.

## Step 2 — Show sessions within that tag

```bash
ls ~/.claude/sessions/<tag>/ | sort -r | head -5
```

Present as a numbered list with dates. Wait for the user to pick one.

## Step 3 — Load and resume

Read the selected file from `~/.claude/sessions/<tag>/<filename>`.

Present its contents, then say "Resuming **<tag>**..." and summarize the key context in 2-3 sentences. Ask if they want to pick up where they left off or start fresh.
