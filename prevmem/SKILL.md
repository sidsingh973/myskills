---
description: Load the previously saved session from ~/.claude/session_memory.md to resume where we left off.
---

Read the file `/Users/siddharthsingh/.claude/session_memory.md` using the Read tool.

If the file exists:
- Present its contents clearly to the user
- Say "Resuming your previous session..." and summarize the key context in 2-3 sentences
- Ask the user if they want to pick up where they left off or start fresh

If the file does not exist:
- Tell the user "No saved session found. Start working and use /savemem to save your session."
