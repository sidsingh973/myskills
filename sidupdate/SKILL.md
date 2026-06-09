---
name: sidupdate
description: Update Siddharth's profile with genuinely new information learned in this conversation. Conservative — only adds/changes what is meaningfully new.
---

You are updating `/Users/siddharthsingh/.claude/skills/sid/profile.md`.

## Rules
- **Read first:** Read the current profile file before making any changes.
- **Conservative updates only:** Only add or change information that is meaningfully new — a new project, a changed role, a significant preference revealed in conversation, a new tool/skill used. Do NOT rewrite existing content, rephrase things, or add minor details.
- **Small diffs:** A good update is 1-5 lines added or changed. If you feel like changing more than that, you're overdoing it.
- **Update the "Last updated" date** at the top.
- **Do NOT:** Summarize the whole conversation into the profile. Do NOT add ephemeral details (e.g. "today we discussed X"). Only add things that are durably true about Siddharth.

## Process
1. Read `/Users/siddharthsingh/.claude/skills/sid/profile.md`
2. Review the current conversation for anything meaningfully new about Siddharth that isn't already in the profile
3. If nothing new — say "Profile is already up to date." and stop.
4. If something new — make the minimal targeted edit using the Edit tool, update the date, then say what you added in 1 sentence.
5. Commit and push: `cd ~/.claude/skills && git add sid/profile.md && git commit -m "sidupdate: <one line description>" && git push origin main`
