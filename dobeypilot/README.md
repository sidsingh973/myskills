# dobeypilot

An AI co-pilot that controls any desktop app through natural language. You describe what you want done; dobeypilot figures out how to do it using the macOS Accessibility API and screenshots.

## Invoke it

```
/dobeypilot HEC-HMS
```

Or just type `/dobeypilot` — it will detect the active app automatically from the live screenshot.

## What it does

1. **Starts a continuous screenshot daemon** that captures the target app's window every 0.5 seconds into `~/.dobey/screencap/live.png`. Change detection avoids unnecessary LLM calls.
2. **Loads cached knowledge** about the app (menus, button positions, AX quirks) from `~/.dobey/contexts/` or the GitHub library at `apps/`.
3. **Executes your commands** using the macOS Accessibility API — clicks menus by name, types text via AppleScript, finds buttons by their AX role/description — no pixel guessing.
4. **Verifies each action** by reading the next changed frame from the screenshot daemon.
5. **Saves session state** to GitHub so the next session picks up exactly where you left off.

## Files

| File | What it is |
|------|------------|
| [SKILL.md](SKILL.md) | The full skill instruction set loaded by Claude Code |
| [architecture.md](architecture.md) | How the whole system is built |
| [screencap.md](screencap.md) | The screenshot capture daemon in detail |
| [java-swing.md](java-swing.md) | Java Swing app quirks and all known workarounds |
| [troubleshooting.md](troubleshooting.md) | Common failures and how to fix them |

## Tools on disk

| Path | Purpose |
|------|---------|
| `~/.dobey/screencap/capture.py` | The background capture daemon |
| `~/.dobey/screencap/tool.py` | Tool interface dobeypilot calls |
| `~/.dobey/axcontrol.py` | Accessibility API wrapper (click, menu, type) |
| `~/.dobey/appcontext.py` | Load/save app knowledge cache |
| `~/.dobey/save_session.py` | Append session notes to GitHub |

## App knowledge library

`apps/<AppName>.json` — one file per app, verified workflows and AX element maps. See [apps/README.md](../apps/README.md).

## Session history

`sessions/<AppName>.md` — per-app running notes updated after every session. See [sessions/](../sessions/).
