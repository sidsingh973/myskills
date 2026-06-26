# dobeypilot — Architecture

## Overview

```
User instruction
      │
      ▼
 dobeypilot (Claude)
      │
      ├── Screenshot daemon (capture.py)   ← always running, 0.5s loop
      │        └── live.png + status.json
      │
      ├── App knowledge cache              ← loaded once per session
      │        └── ~/Desktop/Koshai/infra/contexts/<App>.json
      │
      ├── Accessibility API (axcontrol.py) ← for every action
      │        └── atomacos / AppKit AX
      │
      └── AppleScript / pyautogui          ← fallbacks only
```

## Component 1 — Screenshot Daemon

**File:** `~/Desktop/Koshai/infra/screencap/capture.py`

Runs as a background process (`subprocess.Popen(..., start_new_session=True)`). The parent (dobeypilot) returns immediately; the child loop runs indefinitely.

**Every 0.5 seconds:**
1. `screencapture -l <CGWindowID>` → captures the target window (works even when behind other windows)
2. `screencapture -R 0,0,<screen_width>,28` → captures the menu bar strip
3. Composites both into a single PIL Image (menu bar on top)
4. Change detection: downsample to 64×64 greyscale, diff against last frame. If mean pixel diff > 4.0 → mark as changed
5. Atomic write: save to `.out.png` then `os.replace()` to `live.png` — prevents any reader from getting a partial frame
6. Write `status.json` with `{changed, frame, timestamp, app, diff}`

**Finding the window ID:**
`Quartz.CGWindowListCopyWindowInfo(kCGWindowListOptionAll | kCGWindowListExcludeDesktopElements, kCGNullWindowID)` — finds the largest layer-0 window owned by the app name. Works for windows behind other apps.

**PID management:**
- Daemon writes its own PID to `capture.pid` on startup
- On SIGTERM/SIGINT: sets stop flag, loop exits cleanly, removes PID file
- `cmd_stop()` sends SIGTERM and waits up to 3s for PID file to disappear

## Component 2 — Tool Interface

**File:** `~/Desktop/Koshai/infra/screencap/tool.py`

The clean interface dobeypilot calls:

```python
get_screenshot(wait_for_change=False) → dict
# {path, changed, frame, diff, app, running, timestamp}
```

With `--wait`: polls `status.json` every 0.2s until `changed == True`, max 30s timeout. Returns immediately when change is detected. This means dobeypilot only calls the LLM vision step when something actually changed on screen.

CLI usage:
```bash
python3 tool.py start HEC-HMS   # start daemon
python3 tool.py get             # current frame status
python3 tool.py get --wait      # block until screen changes
python3 tool.py stop            # stop daemon
```

## Component 3 — App Control (axcontrol.py)

Wraps `atomacos` (Python bindings to macOS Accessibility API).

**Preferred method for every action type:**

| Action | Method |
|--------|--------|
| Click a named menu item | `axcontrol.py menu "<App>" "<Menu>" "<Item>"` |
| Click a button with AXTitle | `axcontrol.py click "<App>" "<Label>"` |
| Click a button with no AXTitle (Java) | Find button by AX index (sorted y,x), call `.Press()` |
| Type text into a field | AppleScript: `keystroke "a" using command down` then `keystroke "<text>"` |
| Click a field to focus it | `pyautogui.click(x, y)` using AXPosition from AX tree |
| Scroll | `pyautogui.scroll(-3, x=x, y=y)` |
| Hotkey | `osascript -e 'keystroke "<key>" using {command down}'` |

**Never use pyautogui for menus or labeled buttons** — the AX API is always more reliable and doesn't depend on the app being visible or frontmost.

## Component 4 — App Knowledge Cache

**Files:** `~/Desktop/Koshai/infra/contexts/<AppName>.json` (local) and `apps/<AppName>.json` (GitHub)

Loaded at session start. Contains:
- App's exact AX process name (e.g., `"HEC-HMS-4.13"` not `"HEC-HMS"`)
- Menu structure
- Key element positions and AX indices
- Verified workflows with step-by-step instructions
- AX quirks (e.g., "Java Swing — no AXTitle on any element")

If no cache exists, dobeypilot explores the app live via `list_menus`, `list_buttons`, `list_fields`, takes a screenshot, and builds the JSON from scratch. It saves the result locally immediately, and offers to push to GitHub after verifying a workflow worked.

## Component 5 — Session Persistence

**File:** `~/Desktop/Koshai/infra/save_session.py`

At end of session (or when stuck), saves:
```
sessions/log.md        ← master log, one row per session
sessions/<App>.md      ← per-app running notes with Next Steps
```

Both are appended/upserted and pushed to GitHub automatically. The `sessions/<App>.md` "Next steps" section is the key — it tells the next session exactly where to pick up.

## Retina / HiDPI note

`screencapture -l` captures at native Retina resolution (2× physical pixels per logical point). AX coordinates (`AXPosition`, `AXSize`) are always in **logical points**. `pyautogui` also uses logical points on macOS. So AX positions go directly into pyautogui clicks without any scaling. The captured PNG is 2× bigger but you only use it for vision — never derive click coordinates from it.
