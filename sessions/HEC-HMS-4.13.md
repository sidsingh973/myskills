# HEC-HMS-4.13 — Session Notes

---
## 2026-05-07 18:30

**Prompt:** "get basin for castro valley and mark the gauges. show it there" (both delineate from DEM + mark stream and rain gauges)

### What was accomplished
- Created project `FlowCastroValley` via File > New (AX index 5 = Create button)
- Created basin model `CastroValley` via Components > Basin Model Manager
- Downloaded Castro Valley DEM from USGS 3DEP WCS (`castrovally_dem.tif`, pure Python urllib, no GDAL needed)
- Created Terrain Data component `Terrain 1` pointing to the DEM file
- Set coordinate system for CastroValley basin: UTM Zone 10N NAD83 (WKT pasted into Coordinate System dialog, Set button = AX index 5 sorted by y,x)
- Fetched 25 USGS NWIS stream + atmosphere gauges for Castro Valley bounding box

### Where we got stuck
- **Terrain Data combo box** (AX pos y=694, x=157): Java Swing combo — `pyautogui.click` and AppleScript `click at {x,y}` both failed to open dropdown
  - Tried: pyautogui.click(207,702), tab navigation, AX Press(), AppleScript System Events click
  - None opened the dropdown
  - Root cause unclear: possibly focus issue or Java AWT event dispatch thread not receiving synthetic events
  - **Next attempt**: try `osascript -e 'tell application "System Events" to tell process "HEC-HMS-4.13" to set value of combo box 1 of ...'` or use Quartz CGEvent posting

### Next steps (pick up here)
1. Assign `Terrain 1` to the `CastroValley` basin model's Terrain Data field
2. GIS > Preprocess Sinks → Preprocess Drainage → Identify Streams → Delineate Elements
3. Add 25 USGS gauges as meteorological/discharge elements on the basin canvas
4. Screenshot the finished basin map

### Key AX facts learned
- `app.activate()` then `app.AXFocusedWindow` → gets focused window
- Coordinate System dialog buttons sorted by (y,x): [0-2] small scroll arrows at y≈309, [3] Predefined, [4] Browse, [5] Set, [6] Close/Cancel
- "Create New Project" dialog: Create=index 5 at (444,533), Cancel=index 6 at (533,533)
- Basin Model tree in Java JTree: navigate with keyboard arrows (down/right/Enter) — clicking arrows directly fails
- File browser: use AXTextField at pos≈(514,288), type filename via AppleScript, then press Select button (last button in sorted list)
- Terrain Data combo: AXComboBox at (157, 694), val='' — **NOT YET CLICKABLE via automation**

### DEM download (pure Python, no GDAL)
```python
import urllib.request
bbox = "-122.12,37.65,-122.00,37.78"
url = (
    "https://elevation.nationalmap.gov/arcgis/services/3DEPElevation/ImageServer/WCSServer"
    "?SERVICE=WCS&VERSION=1.0.0&REQUEST=GetCoverage"
    "&COVERAGE=DEP3Elevation&CRS=EPSG:4326"
    f"&BBOX={bbox}&WIDTH=512&HEIGHT=512&FORMAT=GeoTIFF"
)
urllib.request.urlretrieve(url, "/tmp/castrovally_dem.tif")
# Verify: open("/tmp/castrovally_dem.tif","rb").read(4) == b'II*\x00'
```

### USGS NWIS gauges fetched
- 11181004: CASTRO VALLEY C A CASTRO VALLEY CA (stream, lat=37.71, lon=-122.06)
- 11181006: Castro Valley C at Knox St (stream)
- 11181008: Castro Valley C at Hayward (stream)
- Rain gauges: Sydney School, Proctor School, Joseph Avenue
- Total: 25 sites in bounding box (-122.12, 37.65, -122.00, 37.78)
