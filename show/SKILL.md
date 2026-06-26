# /show — Open anything for the user

**Invoke when:** user says "open", "show me", "pull up", "bring up", "display" — for any file, URL, or named resource.

## One tool call, done

```bash
python3 ~/Desktop/Koshai/infra/show/show.py "<intent verbatim>"
```

Pass the user's request **verbatim** as the argument. Do not pre-resolve paths, do not check what app to use, do not ls for files. `show.py` handles everything.

## What it handles

| User says | show.py does |
|---|---|
| `gmail` | opens https://mail.google.com in browser |
| `yc` or `ycombinator` | opens YC website |
| `https://example.com` | opens URL in default browser |
| `latest docx in downloads` | finds newest .docx, opens in Word |
| `latest pdf` | finds newest .pdf in Downloads |
| `researcher semantic` | opens researcher/semantic.md |
| `coder memory` | opens coder/memory.md |
| `~/Downloads/report.pdf` | opens that file in Preview |
| `Thesis_draft` | searches Downloads/Desktop/Documents, opens best match |
| `notion.so` | detects domain, opens as https:// |

## Aliases

User-editable at `~/Desktop/Koshai/infra/show/aliases.json`. Add entries like:
```json
{ "myrepo": "https://github.com/sidsingh973/myskills" }
```

## After opening — observation

If user asks "what does it show?" or "can you see it?", use watcher:
```bash
python3 ~/Desktop/Koshai/infra/watcher/watcher.py ask "what is on screen?" screen
```

`/show` opens. `/watcher` observes. They are independent.

## Do NOT

- Read file contents before opening
- Run `ls` or `find` to locate files (show.py does this)
- Decide which app to use (show.py dispatches by extension)
- Open a file in a terminal viewer (cat, less) — always open natively
