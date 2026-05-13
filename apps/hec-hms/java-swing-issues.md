# HEC-HMS — Java Swing Issues

HEC-HMS is a Java Swing app, which means it has a specific set of automation limitations on macOS. See also the general guide: [../../dobeypilot/java-swing.md](../../dobeypilot/java-swing.md).

This page covers issues specific to HEC-HMS.

---

## Issue 1: JTree won't expand ✅ RESOLVED (2026-05-13)

**Where:** Project tree in the left panel (FlowCastroValley > Basin Models > CastroValley)

**Original symptom:** The "Basin Models" folder node could not be expanded via `pyautogui.press('right')`, AppleScript keystroke, or `CGEventPostToPid` keyboard events. AX API was assumed to have no tree element.

**Resolution:** The AXOutline element IS exposed — it just lives deep in the AX hierarchy. Use `AXUIElementPerformAction(row, 'AXPress')` on a tree row to toggle expansion. Each press toggles state (collapsed↔expanded).

**Working code:**
```python
import ApplicationServices as AS
from AppKit import NSWorkspace

def get_attr(el, attr):
    err, val = AS.AXUIElementCopyAttributeValue(el, attr, None)
    return val if err == 0 else None

pid = next(a.processIdentifier() for a in NSWorkspace.sharedWorkspace().runningApplications()
           if 'HEC-HMS' in (a.localizedName() or ''))
ax_app = AS.AXUIElementCreateApplication(pid)
_, windows = AS.AXUIElementCopyAttributeValue(ax_app, 'AXWindows', None)
main_win = next(w for w in windows if 'FlowCastroValley' in (get_attr(w,'AXTitle') or ''))

def find_role(el, role, depth=0):
    if depth > 10: return None
    if get_attr(el, 'AXRole') == role: return el
    for c in (get_attr(el, 'AXChildren') or []):
        r = find_role(c, role, depth+1)
        if r: return r

outline = find_role(main_win, 'AXOutline')
rows = get_attr(outline, 'AXChildren')

# Press root → expands to show children
AS.AXUIElementPerformAction(rows[0], 'AXPress')  # FlowCastroValley
# Now rows includes Basin Models (and possibly CastroValley if already expanded)
```

**Critical gotcha:** AXPress on an already-expanded row will COLLAPSE it. Check the current row count before pressing — if CastroValley is already in `rows`, skip pressing Basin Models.

**Match rows by exact description, NOT substring:** `'Castro' in desc` matches both `FlowCastroValley` (root) and `CastroValley` (basin). Use `get_attr(r, 'AXDescription') == 'CastroValley'`.

---

## Issue 2: JComboBox won't open ❌ UNRESOLVED

**Where:** "Terrain Data" combo box in basin properties dialog

**Symptom:** The combo box shows the current value (or blank) but clicking it doesn't open the dropdown. Nothing happens.

**Methods tried:**
- `pyautogui.click(x, y)` — focuses the field but no dropdown
- `AXComboBox.Press()` — no effect
- AppleScript `click at {x, y}` — no effect
- `CGEventPostToPid` mouse down/up at combo position — no effect

**Resolution (workaround):** Edit the `.basin` file directly with the `Terrain:` keyword. See [file-formats.md](file-formats.md) and [workflows.md](workflows.md).

**Key discovery:** Decompiled `hms.jar` to find the exact keyword. The string `"     Terrain: "` is in `hms/model/basin/n/r.class` within the `Basin Spatial Properties:` read/write logic.

---

## Issue 3: Open basin model in canvas ✅ RESOLVED (2026-05-13)

**Where:** Project tree, left panel (NOT Basin Model Manager — BMM double-click is still broken)

**The double-click problem:** Java Swing `MouseListener.mouseClicked(clickCount==2)` is what opens basin models. AX `Press` action fires single-click; synthetic CGEvent double-clicks don't trigger Swing's double-click handler. No way to inject a Java-level double-click via macOS AX.

**Working solution: AXPress + click + Enter on the project tree**

1. Expand the tree via `AXPress` on rows to reveal CastroValley
2. Close the Basin Model Manager window (it intercepts Enter key)
3. Click the CastroValley row position (focuses tree item)
4. Send `keystroke return` via AppleScript — Java JTree handles Enter as "activate" which triggers the same path as double-click

```python
import ApplicationServices as AS
import Quartz, time, subprocess, re

# (after locating outline + rows as in Issue 1)

# 1. Expand to reveal CastroValley
root_row = next(r for r in rows if get_attr(r,'AXDescription') == 'FlowCastroValley')
AS.AXUIElementPerformAction(root_row, 'AXPress')
time.sleep(0.5)
rows = get_attr(outline, 'AXChildren')

# If Basin Models still collapsed, press it (DON'T press again if already expanded — it'll collapse)
if not any(get_attr(r,'AXDescription') == 'CastroValley' for r in rows):
    bm_row = next(r for r in rows if get_attr(r,'AXDescription') == 'Basin Models')
    AS.AXUIElementPerformAction(bm_row, 'AXPress')
    time.sleep(0.5)
    rows = get_attr(outline, 'AXChildren')

cv_row = next(r for r in rows if get_attr(r,'AXDescription') == 'CastroValley')
AS.AXUIElementPerformAction(cv_row, 'AXPress')  # select
time.sleep(0.3)

# 2. Close BMM if open (close button is ~7px right, 14px down from window origin)
for w in windows:
    if 'Basin Model Manager' in (get_attr(w,'AXTitle') or ''):
        pos = get_attr(w, 'AXPosition')
        m = re.search(r'x:([\d.]+).*?y:([\d.]+)', str(pos))
        bx, by = float(m.group(1)), float(m.group(2))
        pt = Quartz.CGPoint(bx + 7, by + 14)
        for evt in [Quartz.kCGEventLeftMouseDown, Quartz.kCGEventLeftMouseUp]:
            e = Quartz.CGEventCreateMouseEvent(None, evt, pt, Quartz.kCGMouseButtonLeft)
            Quartz.CGEventPost(Quartz.kCGHIDEventTap, e)
            time.sleep(0.05)
        time.sleep(0.8)

# 3. Click tree position to confirm focus
cv_pos = get_attr(cv_row, 'AXPosition')
m = re.search(r'x:([\d.]+).*?y:([\d.]+)', str(cv_pos))
cv_y = float(m.group(2))
pt = Quartz.CGPoint(80.0, cv_y)
for evt in [Quartz.kCGEventLeftMouseDown, Quartz.kCGEventLeftMouseUp]:
    e = Quartz.CGEventCreateMouseEvent(None, evt, pt, Quartz.kCGMouseButtonLeft)
    Quartz.CGEventPost(Quartz.kCGHIDEventTap, e)
    time.sleep(0.05)
time.sleep(0.3)

# 4. Enter key opens the basin model in canvas
subprocess.run(['osascript', '-e',
    'tell application "System Events" to tell process "HEC-HMS-4.13" to keystroke return'])
time.sleep(2.0)
```

**Verification:** After running, the GIS menu items (Preprocess Sinks, Drainage, Identify Streams, etc.) transition from disabled → enabled. Title bar shows `Basin Model [CastroValley]` in the inspector pane.

**Note:** Basin Model Manager (Components > Basin Model Manager) double-click still does NOT work — the only path is through the project tree.

---

## Issue 4: "Open an Existing Project" dialog appears on activation

**Where:** Appears when `app.activate()` is called if no basin model is open

**Symptom:** When dobeypilot activates HEC-HMS, a large modal dialog appears asking to open an existing project. This blocks the Basin Model Manager.

**Fix:** Find the Cancel button via AX (`AXButton desc='Cancel'` at approximately (957, 623)) and click it:
```python
for w in app.windows():
    if 'Open' in (w.AXTitle or '') and 'Project' in (w.AXTitle or ''):
        cancel = find_btn(w, 'Cancel')
        pyautogui.click(cancel.AXPosition.x + cancel.AXSize.width/2,
                        cancel.AXPosition.y + cancel.AXSize.height/2)
```

---

## Issue 5: File > Exit closed HEC-HMS without warning

**What happened:** During a session, the automation called `File > Exit` to close HEC-HMS before editing files. HEC-HMS closed immediately without any save confirmation dialog.

**Prevention:** Don't use File > Exit during automation sessions. Edit project files directly (they're plain text keyword files). HEC-HMS reads them on next open.

---

## Issue 6: WARNING 10175 — Unrecognized line in project file

**Trigger:** Adding `Terrain Data: Terrain 1` to the Basin block in `.hms`

**Error message:** `WARNING 10175: Unrecognized line in project file — Line identifier: terraindata`

**Root cause:** `Terrain Data` belongs in the `.basin` file's `Basin Spatial Properties:` block, not in the `.hms` Basin reference block.

**Fix:** 
- Revert the `.hms` change
- Add `Terrain: Terrain 1` to `Basin Spatial Properties:` in `CastroValley.basin`
- Correct keyword is `Terrain:` (not `Terrain Data:`), found in jar decompilation

---

## Working reliably in HEC-HMS

| Action | Method | Notes |
|--------|--------|-------|
| Open any menu | `axcontrol.py menu` | ✅ Always works |
| Click named buttons in standard dialogs | `AXButton.Press()` by description or index | ✅ Always works |
| Type text into any field | AppleScript `keystroke` | ✅ Always works |
| Read field values | `field.AXValue` | ✅ Always works |
| Select item in manager list | `pyautogui.click` on AXRow | ✅ Works with app frontmost |
| Open basin model in canvas | AXPress tree row + click + Enter key | ✅ Via project tree (NOT BMM) |
| Expand JTree node | `AXUIElementPerformAction(row, 'AXPress')` | ✅ Toggles expand/collapse |
| Change a combo box value | File edit workaround | ✅ File edit only |
