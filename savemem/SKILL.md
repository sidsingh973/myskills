---
name: savemem
description: Save the current session to ~/.claude/sessions/<tag>/YYYY-MM-DD_HH-MM.md. Prompts for new or existing tag.
---

## Step 1 — Summarize
Write a one-line summary of this conversation (topic + what was accomplished).

## Step 2 — Show existing tags
```bash
ls ~/.claude/sessions/ 2>/dev/null || echo "(none)"
```

Present to the user:
> Summary: "<your one-line summary>"
>
> Save as:
> 1. New tag
> 2. Existing tag — <list tags on one line>

Wait for their choice.

**If new tag:** Suggest a short kebab-case slug from the summary (e.g. `hec-hms`, `dobeypilot`, `sports`). Confirm or let them rename.

**If existing tag:** User picks from the list.

## Step 3 — Save

```bash
mkdir -p ~/.claude/sessions/<tag>
```

Get the current timestamp: `date +%Y-%m-%d_%H-%M`

Write to `~/.claude/sessions/<tag>/<timestamp>.md` using the Write tool:

```
# <tag> — <one-line summary>
**Date:** <today>
**Working directory:** <if known>

## What we did
- <bullet points>

## Decisions made
- <bullet points if any>

## Files changed
- <list if any>

## Where we left off
<1-2 sentences on current state and next steps>

## Key context
<critical details needed to resume>
```

Keep under 50 lines.

Confirm: "Saved to `sessions/<tag>/<timestamp>.md`"
