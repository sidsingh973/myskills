# dobeypilot — Screenshot Capture Daemon

## What it is

A background daemon that continuously captures any app's window and writes `live.png` every 0.5 seconds. dobeypilot reads this image rather than taking one-off screenshots, so it always has a fresh frame available without waiting.

## Quick start

```bash
# Start (returns immediately, daemon runs in background)
python3 ~/Desktop/Koshai/infra/screencap/tool.py start "HEC-HMS"

# Read current frame (non-blocking)
python3 ~/Desktop/Koshai/infra/screencap/tool.py get

# Wait for next screen change, then return
python3 ~/Desktop/Koshai/infra/screencap/tool.py get --wait

# Stop
python3 ~/Desktop/Koshai/infra/screencap/tool.py stop
```

## Output files

| File | Contents |
|------|----------|
| `~/Desktop/Koshai/infra/screencap/live.png` | Latest composited screenshot (window + menu bar) |
| `~/Desktop/Koshai/infra/screencap/status.json` | `{changed, frame, timestamp, app, diff}` |
| `~/Desktop/Koshai/infra/screencap/capture.pid` | Daemon PID (removed on clean exit) |

## status.json fields

```json
{
  "changed":   true,        // true if screen changed since last frame
  "frame":     291,         // monotonically increasing frame counter
  "timestamp": "2026-05-07T22:05:00",
  "app":       "HEC-HMS",   // app name given at start
  "diff":      12.3         // mean pixel diff score (0–255)
}
```

`changed` is reset to `false` after each new capture if the diff is below threshold. Use `tool.py get --wait` so you only act when something actually happened — avoids burning LLM tokens on identical frames.

## How change detection works

Each frame is downsampled to a 64×64 greyscale thumbnail. The absolute pixel difference between new and last thumbnail is computed with `PIL.ImageChops.difference`. `ImageStat.Stat(diff).mean[0]` gives the mean change. If > 4.0 → `changed = true`.

Threshold tuning:
- Too low (< 2.0): clock ticking, cursor blinking, or video playback triggers constantly
- Too high (> 10.0): misses subtle dialog appearances or progress bar changes
- 4.0 is the right default for engineering GUI apps

## How window capture works

Uses macOS `screencapture -l <CGWindowID>` which captures the composited window buffer — meaning it works even when the target window is behind other windows, minimized, or partially off-screen.

The window ID is found via:
```python
Quartz.CGWindowListCopyWindowInfo(
    kCGWindowListOptionAll | kCGWindowListExcludeDesktopElements,
    kCGNullWindowID
)
```

Filtered to: layer == 0, area > 10,000 px², owner name contains the app name. Picks the largest matching window.

## Menu bar composition

The menu bar belongs to whichever app is frontmost — it's not part of the app's window. So the daemon also captures a 28pt-high screen strip (`screencapture -R 0,0,<screen_width>,28`) and composites it above the window image. This gives the LLM full context about which menus are available.

Screen width is read via:
```python
Quartz.CGDisplayBounds(Quartz.CGMainDisplayID()).size.width
```
Not `CGDisplayCopyDisplayMode` — that requires macOS 26+.

## Daemon lifecycle

```
cmd_start()
  └─ subprocess.Popen([sys.executable, __file__, "_run", app_name],
                       start_new_session=True,
                       stdout=DEVNULL, stderr=DEVNULL)
       └─ parent: waits up to 2s for child to write PID file, then exits
       └─ child: _run(app_name)
                  ├─ writes own PID to capture.pid
                  ├─ registers SIGTERM/SIGINT handler (stop flag)
                  ├─ finds window, gets screen width
                  └─ loop: capture → check_changed → write_live → write_status
                            └─ on fail_streak >= 5: break loop
                  └─ on exit: removes capture.pid
```

The `start_new_session=True` flag detaches the child from the terminal session so it keeps running even when the terminal closes.

## Atomic writes

`write_live()` writes to `live.png.out.png` first, then uses `os.replace()` to atomically move it to `live.png`. This prevents any reader (Claude Code, Preview.app) from ever reading a partially-written file.

## Known issues and fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| `unknown file extension: .tmp` crash | PIL can't infer PNG format from `.tmp` extension | Pass `format="PNG"` explicitly to `.save()` |
| `CGDisplayCopyDisplayMode` API error | Requires macOS 26+ | Use `CGDisplayBounds(CGMainDisplayID())` instead |
| `Image.Image \| None` TypeError | Python 3.9 doesn't support `\|` type union hints | Use `object` as return type |
| macOS Tkinter crash ("macOS 26 or later required") | Tkinter incompatible with Darwin 25.x | Removed Tkinter entirely; terminal output + atomic writes are sufficient |
