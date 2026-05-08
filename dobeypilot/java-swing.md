# dobeypilot — Java Swing App Quirks

Java Swing apps (HEC-HMS, ArcMap, older GIS tools) expose almost nothing useful via the macOS Accessibility API. This doc covers everything learned about controlling them.

## The fundamental problem

Java Swing renders its own UI using Java2D/OpenGL, then hands the composed frame to AppKit. The macOS AX API can only see the AppKit shell — not the individual Swing components inside. Result:

- Buttons have no `AXTitle`, no `AXDescription`
- JTree rows have no `AXTitle`, not expandable via AX
- JComboBox dropdowns have no `AXDescription`
- JTextField values appear as `AXValue` but clicking them via AX is unreliable
- The only exposed info per element is `AXRole`, `AXPosition`, `AXSize`, and sometimes `AXValue`

## What DOES work

### Menus — fully reliable
Java Swing's `JMenuBar` is wrapped in a real macOS menu bar. Works perfectly:
```bash
python3 ~/.dobey/axcontrol.py menu "HEC-HMS-4.13" "File" "New"
```

### Button clicks by AX index — reliable
Buttons have `AXRole = "AXButton"` even without a title. Collect all buttons from a dialog, sort by (y, x), and call `.Press()` by index:

```python
buttons = []
def collect(el):
    try:
        for c in el.AXChildren:
            if c.AXRole == 'AXButton':
                buttons.append((c.AXPosition.y, c.AXPosition.x, c))
            collect(c)
    except: pass
collect(dialog)
buttons.sort()
buttons[5][2].Press()  # 6th button in reading order
```

### Text input via AppleScript — reliable
Don't use `pyautogui.typewrite()` for Java apps — it misses keystrokes. Use:
```bash
osascript -e 'tell application "System Events" to tell process "HEC-HMS-4.13" to keystroke "a" using command down'
sleep 0.1
osascript -e 'tell application "System Events" to tell process "HEC-HMS-4.13" to keystroke "my text here"'
```

### pyautogui.click() — works IF HEC-HMS is the frontmost app
The critical issue: if Terminal is running the Python script, clicking via pyautogui may target Terminal, not HEC-HMS. Always call `app.activate()` immediately before pyautogui clicks, and check the live screenshot's menu bar to confirm HEC-HMS is frontmost.

### AXList rows in dialogs — press works
In JDialog with a JList (e.g., Basin Model Manager), the `AXRow` elements support `Press()`:
```python
row.Press()  # selects the row — equivalent to single click
```
Double-click to "open" the item (e.g., open a basin model from the manager) does NOT work via any synthetic event method tried — see "What does NOT work" below.

## What does NOT work

### JTree expansion
The project tree in HEC-HMS is a `JTree`. Expanding nodes (clicking the disclosure triangle, pressing Right arrow key) does not work via:
- `pyautogui.press('right')` 
- `osascript keystroke (right arrow key code 124)`
- `CGEventPostToPid` with keyboard events
- AX API (tree not exposed)

**Root cause:** Java Swing's event dispatch thread (EDT) doesn't process synthetic events the same way as native events for tree expansion. The JTree row receives the event but the tree UI model ignores it.

**Current workaround:** Open the relevant manager dialog (e.g., Components > Basin Model Manager) instead of trying to expand the tree. The manager uses a JList which has better AX exposure.

### JComboBox dropdowns
Combo boxes in dialogs (e.g., Terrain Data dropdown in basin properties) won't open via:
- `pyautogui.click(x, y)` on the combo box
- `AXComboBox.Press()`
- AppleScript `click at {x, y}`
- `CGEventPostToPid` mouse events

**Root cause:** Same Java EDT issue. The combo box receives focus but the dropdown doesn't open.

**Workaround being investigated:** Direct `.basin`/`.hms` file editing to set values that would normally be set through the combo box UI.

### Double-click to open items in JList
`pyautogui.doubleClick()` on a JList item selects it (first click) but the second click doesn't register as a double-click in Java's double-click time window.

**Workarounds tried:**
- `pyautogui.doubleClick()` — works for selecting, doesn't "open"
- `CGEventPostToPid` with double-click flag — same result
- `row.Press()` twice — Press() = single click, doesn't trigger open action
- AppleScript `click` then `click` — same timing issue

## AX process name vs. display name

The macOS AX API uses the process name, not the display name. Always use the exact string from `CGWindowOwnerName`:

```python
app = atomacos.getAppRefByLocalizedName('HEC-HMS-4.13')  # correct
app = atomacos.getAppRefByLocalizedName('HEC-HMS')        # fails
```

Find the right name:
```python
import Quartz
for w in Quartz.CGWindowListCopyWindowInfo(...):
    print(w.get('kCGWindowOwnerName'))
```

## AX tree dump pattern

Standard pattern for discovering button indices in any Java Swing dialog:

```python
import atomacos, time
app = atomacos.getAppRefByLocalizedName('HEC-HMS-4.13')
app.activate()
time.sleep(0.3)
win = app.AXFocusedWindow

def dump(el, depth=0):
    indent = '  ' * depth
    try:
        role = el.AXRole or ''
        val = str(el.AXValue or '')[:30]
        desc = str(el.AXDescription or '')[:30]
        pos = el.AXPosition
        size = el.AXSize
        print(indent + f'[{role}] val={repr(val)} desc={repr(desc)} pos={pos} sz={size}')
        if depth < 5:
            for c in el.AXChildren: dump(c, depth+1)
    except Exception as e:
        print(indent + 'ERR: ' + str(e))

dump(win)
```

## App activation issue

When Python runs from Terminal, calling `app.activate()` brings HEC-HMS to front. But as soon as the Python script continues and pyautogui tries to click, macOS may have already returned focus to Terminal.

**Reliable pattern:**
1. Use `app.activate()` + `time.sleep(0.3)`
2. Use AX `Press()` actions (don't require frontmost app)
3. For pyautogui clicks: verify in live.png that HEC-HMS menu bar shows before clicking
4. For fields: always single-click to focus, then use AppleScript to type

## Summary table

| What you want to do | Method | Works? |
|----|----|----|
| Click a menu item | `axcontrol.py menu` | ✅ Always |
| Click a labeled button | `axcontrol.py click` | ✅ Always |
| Click an unlabeled button | Collect + sort + `Press()` by index | ✅ Always |
| Type text into a field | AppleScript `keystroke` | ✅ Always |
| Read a field value | `field.AXValue` | ✅ Always |
| Click a dialog list item | `pyautogui.click(row.AXPosition)` | ✅ Selects it |
| Double-click to open item | Any method | ❌ Not working |
| Expand a JTree node | Any method | ❌ Not working |
| Open a JComboBox dropdown | Any method | ❌ Not working |
| Click a checkbox | `pyautogui.click(AXPosition)` | ⚠️ Needs frontmost |
