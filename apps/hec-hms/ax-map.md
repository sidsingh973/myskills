# HEC-HMS — AX Element Map

All positions are in macOS logical points (screen absolute coordinates).  
Main window: `(0, 34)` to `(1492, 900)` — fills the screen on the test machine.

## Main window layout

```
┌─────────────────────────────────────────────────────────────────┐
│  Menu bar (HEC-HMS 4.13 / File / Edit / View / Components /     │
│           GIS / Parameters / Compute / Results / Tools / Help)  │
├──────────────────────────────────────────────────────────────────│
│  Toolbar row 1: [icons] [Basin dropdown (407,75,91×20)]         │
│                         [Run dropdown (519,75,215×20)]          │
├──────────────────────────────────────────────────────────────────│
│  Toolbar row 2: [playback controls]                             │
├───────────────────┬──────────────────────────────────────────────│
│  Left panel       │  Canvas (empty = blue, model open = grey)   │
│  (tree + info)    │                                              │
│                   │                                              │
│  FlowCastroValley │                                              │
│    Basin Models   │                                              │
│    Terrain Data   │                                              │
│                   │                                              │
│  [Components ▶]  │                                              │
│  [Project]        │                                              │
│  Name: FlowCastr  │                                              │
│  Description:     │                                              │
│  Output DSS File  │                                              │
├───────────────────┴──────────────────────────────────────────────│
│  Messages panel (log output)                                     │
└──────────────────────────────────────────────────────────────────┘
```

## Toolbar combo boxes

| Description | Position | Size |
|-------------|----------|------|
| Basin model selector (–None–) | (407, 75) | 91×20 |
| Simulation run selector (–None–) | (519, 75) | 215×20 |
| Component type selector (left panel) | (22, 110) | 160×20 |

**Note:** These are `AXComboBox` elements but won't open via any synthetic click method. See [java-swing-issues.md](java-swing-issues.md).

## Project tree

The left-panel tree is a Java `JTree`. AX exposes nothing — no children, no expandable nodes. Only the folder labels are visible as text at the AX level.

**Known tree item screen positions (approximate):**

| Item | Screen y | Screen x |
|------|----------|----------|
| FlowCastroValley (root) | ~96 | ~55 |
| Basin Models | ~103 | ~63 |
| Terrain Data | ~113 | ~63 |

Disclosure triangles are ~8px to the left of the text. Clicking them does not expand the tree via any automation method tried.

## Create a New Project dialog

Appears from File > New.

| Element | AX index (sorted y,x) | Approx position | Size |
|---------|----------------------|-----------------|------|
| Name field | field[0] | center (425, 428) | — |
| Description field | field[1] | center (425, 456) | — |
| Location field | field[2] | center (425, 484) | — |
| CREATE button | button[5] | (444, 533) | 84×29 |
| Cancel button | button[6] | (533, 533) | 86×29 |

## Basin Model Manager

Opened via: Components > Basin Model Manager  
Window title: `Basin Model Manager`  
Position: (175, 184) — Size: 390×310

AX tree:
```
AXWindow "Basin Model Manager"
  AXScrollArea
    AXList desc="list"
      AXRow desc="CastroValley"    ← at (197, 246), size 181×18
        AXStaticText desc="CastroValley"
  AXButton desc="New..."           at (396, 244)
  AXButton desc="Copy..."          at (396, 277)
  AXButton desc="Rename..."        at (396, 310)
  AXButton desc="Delete"           at (396, 343)
  AXButton desc="Description..."   at (396, 376)
```

**Opening a basin model:** Select the row and call `.Press()` (selects it, blue highlight). Double-click via pyautogui or CGEvent does NOT open the model in the canvas. See [java-swing-issues.md](java-swing-issues.md) for open issue.

## Coordinate System dialog

Opened via: Basin Schematic Properties > Set Coordinate System  

Button layout (sorted by y,x):
- buttons[0–2]: small scroll arrows at y≈309
- buttons[3]: Predefined
- buttons[4]: Browse
- buttons[5]: **Set** ← use this to apply the WKT
- buttons[6]: Close/Cancel

WKT for UTM Zone 10N NAD83:
```
PROJCS["UTM_ZONE_10N_Nad83",GEOGCS["NAD83",DATUM["North_American_Datum_1983",SPHEROID["GRS 1980",6378137,298.257222101,AUTHORITY["EPSG","7019"]],AUTHORITY["EPSG","6269"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4269"]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",0],PARAMETER["central_meridian",-123],PARAMETER["scale_factor",0.9996],PARAMETER["false_easting",500000],PARAMETER["false_northing",0],UNIT["metre",1,AUTHORITY["EPSG","9001"]],AXIS["Easting",EAST],AXIS["Northing",NORTH]]
```

## GIS menu items

| Item | Enabled when |
|------|-------------|
| Coordinate System | Basin model active |
| Terrain Reconditioning | Terrain + active basin |
| Preprocess Sinks | Terrain + active basin |
| Preprocess Drainage | After Preprocess Sinks |
| Identify Streams | After Preprocess Drainage |
| Break Points Manager | After Identify Streams |
| Delineate Elements | After Identify Streams |
| Compute | Always |

All GIS items are disabled when no basin model is open in the canvas.
