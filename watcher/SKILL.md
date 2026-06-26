---
name: watcher
description: Ask Watcher what's on screen. Full screen or per-window focus.
---

# /watcher — Team Eyes

Ask Watcher what's visible on screen right now.

## Usage

```bash
/usr/bin/python3 ~/Desktop/Koshai/infra/watcher/watcher.py ask "<question>" screen
/usr/bin/python3 ~/Desktop/Koshai/infra/watcher/watcher.py ask "<question>" app "<AppName>"
/usr/bin/python3 ~/Desktop/Koshai/infra/watcher/watcher.py ask "<question>" all
```

## Good questions

- "what is on screen right now?"
- "what app is Siddharth using?"
- "is there an error visible?"
- "what does the terminal show?"
- "what tab is open in Chrome?"
- "did the tests pass?"
- "what is Siddharth working on?"

## Target types

- `screen` — full primary display (everything Siddharth sees)
- `app "<Name>"` — single app window, even if occluded behind other windows
- `all` — all displays stitched side-by-side

## How it works

Takes a screenshot → sends to Haiku → returns a text answer. No image is
stored in context. For Terminal.app, tries the Accessibility text path first
(no screenshot needed, ~$0.000025/query) then falls back to screenshot + vision.

## When to use

Use Watcher any time you need to know what's on Siddharth's screen without
interrupting him. Common patterns:

- Check if a build/test finished before asking about it
- See what error is visible in a browser or IDE
- Verify that a UI change looks right
- Know what context Siddharth is in before responding
