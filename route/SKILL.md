# /route — Tag this clerk's log by project

Tags the **untagged** entries in the current clerk's log with a project + confidence.
Tied to the clerk of whatever session invokes it (cofounder, coder, researcher, pm,
or a terminal clerk). Append-only — never rewrites existing tagged output.

## Invocation

- `/route <project> [desc_file]` — tag untagged entries for `<project>`. Optional `.md`
  description file gives the router context to score confidence.
- `/route auto [desc_file]` — let the model infer the single project from the entries.

**Never run without a project name (or `auto`).** If neither is given, ask which project.

---

## Step 1 — Identify this clerk and pull untagged entries

```bash
NAME=$(python3 ~/Desktop/Koshai/infra/clerk/route.py whoami)
python3 ~/Desktop/Koshai/infra/clerk/route.py untagged "$NAME" <project>
```

(For `auto`, use any placeholder project for the `untagged` call — e.g. the literal
word `auto` — since the cursor is shared per source log until first tag. Better: pass
the project you'll end up using once decided; on first run they're equivalent.)

If output is `(no new entries)` — report "nothing new to route for `<name>`" and stop.

---

## Step 2 — Tag each entry

If a `desc_file` was given, read its first ~500 chars for project context.

Insert a tag immediately after the `[HH:MM:SS]` timestamp on each timestamped line:
- `[<project>-N]` — N = 1–5 confidence (5 = directly about this project / its files; 1 = barely related)
- `[scr]` — not related to this project

Continuation lines (no timestamp) pass through **unchanged**. Output the full text with
tags inserted — nothing else.

**Prompt the router uses (standard):**
```
Project: <project>
<desc_file contents, first ~500 chars, if provided>

Tag each [HH:MM:SS] line. Insert the tag right after the timestamp:
  [<project>-N]   N=1-5, how directly related to <project>
  [scr]           not related

Continuation lines (no timestamp): pass through unchanged.
Output the full text with tags inserted. Nothing else.

---
<untagged entries from Step 1>
```

**Prompt for `auto`:**
```
Read these terminal session entries. Decide the single project they belong to
(one word, lowercase), then tag each [HH:MM:SS] line: [<project>-N] (N=1-5) or [scr].
Continuation lines unchanged.
First output line: "project: <name>"
Then the full tagged text. Nothing else.

---
<untagged entries>
```
For `auto`, read the `project:` line from the output and use it as `<project>` in Step 3.

**Example:**
```
[15:23:41] PROMPT: fix the window positioning bug
[15:23:44] Edited watcher.py line 82, fixed empty capture for Finder.

[15:25:10] PROMPT: what is the weather
[15:25:12] Checked weather API, San Francisco 68°F.
```
→
```
[15:23:41] [watcher-5] PROMPT: fix the window positioning bug
[15:23:44] [watcher-5] Edited watcher.py line 82, fixed empty capture for Finder.

[15:25:10] [scr] PROMPT: what is the weather
[15:25:12] [scr] Checked weather API, San Francisco 68°F.
```

---

## Step 3 — Append to the tagged file

Write the full tagged output to a temp file, then:

```bash
python3 ~/Desktop/Koshai/infra/clerk/route.py write "$NAME" <project> < /tmp/route_out.md
```

This appends to `~/Desktop/Koshai/infra/clerk/tracker/<name>_tgd_<project>_<date>.md` and the tagged
file's last `[HH:MM:SS]` becomes the new anchor — the next `/route` call sees only
entries after it.

---

## Step 4 — Report

- How many entries tagged, confidence spread (high ≥4, mid 2–3, scr)
- Tagged file path
- `python3 ~/Desktop/Koshai/infra/clerk/route.py status` for the full tagged/untagged board

---

## How "untagged" is known (deterministic, no mark files)

The tagged file is the cursor. Its last `[HH:MM:SS]` line, tag stripped, is the anchor.
Everything after that timestamp in `<name>_log_<date>.md` is untagged. Timestamps are
second-unique, so the anchor is exact. No tagged file yet → the whole log is untagged.
