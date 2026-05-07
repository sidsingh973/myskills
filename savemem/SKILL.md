---
description: Save a compact markdown summary of the current session to ~/.claude/session_memory.md so it can be resumed later with /prevmem.
---

Summarize the current conversation and write it to `~/.claude/session_memory.md`.

The file should be concise and structured like this:

```
# Session Memory
**Date:** <today's date>
**Working directory:** <current working directory if known>

## What we did
- <bullet points of key actions taken>

## Decisions made
- <any important decisions or approaches chosen>

## Files changed
- <list of files created or modified, with brief reason>

## Where we left off
<1-2 sentences on current state and what comes next>

## Key context
<any other important details needed to resume seamlessly>
```

Write this file using the Write tool to `/Users/siddharthsingh/.claude/session_memory.md`. Keep it under 50 lines. After writing, confirm to the user that the session has been saved.
