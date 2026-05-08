# dobeypilot — Troubleshooting

## Capture daemon

### Daemon won't start / immediately exits
```bash
python3 ~/.dobey/screencap/capture.py status
# if "not running (stale PID file)":
rm ~/.dobey/screencap/capture.pid
python3 ~/.dobey/screencap/tool.py start "AppName"
```

### `No window found for 'AppName'`
The app name you passed doesn't match the CGWindowOwnerName. List running apps:
```bash
python3 ~/.dobey/screencap/capture.py --list
```
Then use the exact name shown (e.g., `HEC-HMS-4.13` not `HEC-HMS`).

### live.png not updating
```bash
python3 ~/.dobey/screencap/tool.py status
# check "last=X.Xs ago" — if > 5s something is wrong
python3 ~/.dobey/screencap/tool.py stop
python3 ~/.dobey/screencap/tool.py start "AppName"
```

### `unknown file extension: .tmp` crash
Old version of capture.py. Fixed in current version (explicit `format="PNG"` in `img.save()`).

### `CGDisplayCopyDisplayMode` requires macOS 26+ error
Old version of capture.py. Fixed to use `CGDisplayBounds(CGMainDisplayID())` instead.

---

## App control

### `ValueError: Specified application not found in running apps`
The AX process name doesn't match. Find the right name:
```python
import atomacos
for app in atomacos.getRunningApps():
    print(app.localizedName())
```
Or check via Quartz:
```python
import Quartz
for w in Quartz.CGWindowListCopyWindowInfo(Quartz.kCGWindowListOptionAll, Quartz.kCGNullWindowID):
    print(w.get('kCGWindowOwnerName', ''))
```

### Click goes to Terminal instead of the app
Terminal steals focus when Python finishes executing. Fix: use AX `Press()` actions instead of `pyautogui.click()` wherever possible. For pyautogui clicks, check live.png menu bar to confirm the app is frontmost before clicking.

### Menu item click opens menu but item isn't found
Some menu items only appear when a specific component is selected. Check that the right element is active (e.g., a basin model must be open for GIS menu items to be enabled).

### Field text not entering correctly
`pyautogui.typewrite()` drops keystrokes in Java Swing. Always use AppleScript:
```bash
osascript -e 'tell application "System Events" to tell process "AppName" to keystroke "a" using command down'
sleep 0.1
osascript -e 'tell application "System Events" to tell process "AppName" to keystroke "the text"'
```

### `AXRole` scan returns nothing / empty tree
Java Swing app — the AX tree only shows the AppKit frame, not Swing internals. See [java-swing.md](java-swing.md) for the full breakdown.

---

## macOS compatibility

### Tkinter crash: "macOS 26 or later required"
macOS 26 = Darwin 25.x (macOS Sequoia 15.x). Tkinter incompatible with that kernel version. 
**Fix:** Remove all Tkinter code. Use terminal output + atomic file writes for all status output. Preview.app auto-reloads live.png on each atomic replace.

### `Image.Image | None` TypeError
Python 3.9 doesn't support the `|` union syntax in type hints. 
**Fix:** Replace `Image.Image | None` with `object`.

### screencapture permission denied
System Preferences → Privacy & Security → Screen Recording → allow Terminal (or the Python process).

---

## Session / GitHub

### `save_session.py` push fails
```bash
cd ~/.claude/skills
git status  # check for conflicts
git pull --rebase origin main
# then retry the save
```

### App context not loading from GitHub
```bash
python3 ~/.dobey/appcontext.py get "AppName"
# if NONE:
# manually check apps/AppName.json exists on GitHub
# pull latest:
cd ~/.claude/skills && git pull
```
