# HEC-HMS — Java Swing Issues

HEC-HMS is a Java Swing app, which means it has a specific set of automation limitations on macOS. See also the general guide: [../../dobeypilot/java-swing.md](../../dobeypilot/java-swing.md).

This page covers issues specific to HEC-HMS.

---

## Issue 1: JTree won't expand ❌ UNRESOLVED

**Where:** Project tree in the left panel (FlowCastroValley > Basin Models > CastroValley)

**Symptom:** The "Basin Models" folder node cannot be expanded to reveal "CastroValley" via any automation method. The tree always shows the two top-level items (Basin Models, Terrain Data) but never expands to show basin model names.

**Impact:** Cannot click on "CastroValley" in the tree → cannot open basin model in canvas → all GIS menu items remain disabled.

**Methods tried:**
- `pyautogui.press('right')` after clicking the Basin Models row — no effect
- AppleScript `keystroke (right arrow, key code 124)` — no effect
- `CGEventPostToPid` with keyboard events (right arrow) — no effect
- Clicking the disclosure triangle at approximate position (26–36, 103) via CGEventPostToPid — no effect
- AX API has no tree/outline element to interact with (tree not exposed)

**Root cause:** Java Swing JTree uses its own event dispatch and doesn't process synthetic keyboard/mouse events the same as native events for tree state changes.

**Next approach:** Search hms.jar for the keyword that marks a basin model as "open" in the canvas. This would allow pre-opening it via file edit before starting HEC-HMS.

Jar search targets:
- `Open Window`, `Desktop`, `Active Basin`, `Display`, `Show Basin`
- Class files in `hms/model/`, `hms/project/`, `hms/ui/` packages

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

## Issue 3: Basin Model Manager — double-click doesn't open ❌ UNRESOLVED

**Where:** Basin Model Manager dialog (Components > Basin Model Manager)

**Symptom:** The AXList shows the CastroValley row. Single-click selects it (turns blue). Double-click does NOT open the basin model in the canvas.

**Methods tried:**
- `pyautogui.doubleClick(x, y)` — selects row, no open
- `CGEventPostToPid` with mouse double-click events — selects row, no open
- `AXRow.Press()` — executes without error, doesn't open model
- `AXRow.Press()` twice rapidly — same, no open
- Enter key after selecting — no effect
- `row.AXSelected = True` + Enter — no effect

**Only available AX action:** `'Press'` — confirmed via `row.getActions()` returning `['Press']`. Press = single click equivalent.

**Root cause:** Java Swing `MouseListener.mouseClicked()` with `clickCount == 2` is what opens the item. The macOS AX "Press" action fires a single-click event. No AX mechanism to inject a Java-level double-click.

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
| Open basin model in canvas | ❌ | Blocked — see Issue 1 & 3 |
| Change a combo box value | File edit workaround | ✅ File edit only |
