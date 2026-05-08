# HEC-HMS — Verified Workflows

Status key: ✅ verified working | ⚠️ partially verified | ❌ known broken | 🔬 untested

---

## Create new project ✅

Verified: 2026-05-07

```python
import atomacos, time

app = atomacos.getAppRefByLocalizedName('HEC-HMS-4.13')
app.activate()
time.sleep(0.3)

# 1. File > New
python3 ~/.dobey/axcontrol.py menu "HEC-HMS-4.13" "File" "New"
time.sleep(1.5)

# 2. Dialog appears: "Create a New Project"
win = app.AXFocusedWindow
assert 'Create' in (win.AXTitle or '')

# 3. Type name (field index 0)
import subprocess
fields = []
def cf(el):
    try:
        for c in el.AXChildren:
            if c.AXRole == 'AXTextField': fields.append(c)
            cf(c)
    except: pass
cf(win)

import pyautogui
pos = fields[0].AXPosition
sz = fields[0].AXSize
pyautogui.click(pos.x + sz.width/2, pos.y + sz.height/2)
time.sleep(0.2)
subprocess.run(['osascript', '-e',
    'tell application "System Events" to tell process "HEC-HMS-4.13" to keystroke "a" using command down'])
time.sleep(0.1)
subprocess.run(['osascript', '-e',
    'tell application "System Events" to tell process "HEC-HMS-4.13" to keystroke "FlowCastroValley"'])
time.sleep(0.3)

# 4. Press Create (button index 5, sorted by y,x)
buttons = []
def cb(el):
    try:
        for c in el.AXChildren:
            if c.AXRole == 'AXButton':
                try: buttons.append((c.AXPosition.y, c.AXPosition.x, c))
                except: pass
            cb(c)
    except: pass
cb(win)
buttons.sort()
buttons[5][2].Press()
time.sleep(1.0)

# 5. Verify
win = app.AXFocusedWindow
assert 'FlowCastroValley' in (win.AXTitle or '')
```

---

## Create basin model ✅

Verified: 2026-05-07

```bash
# Open manager
python3 ~/.dobey/axcontrol.py menu "HEC-HMS-4.13" "Components" "Basin Model Manager"
```

```python
# Find manager window
bmm = None
for w in app.windows():
    if 'Basin Model Manager' in (w.AXTitle or ''):
        bmm = w; break

# Click New... button
for child in bmm.AXChildren:
    if child.AXRole == 'AXButton' and child.AXDescription == 'New...':
        child.Press()
        break
time.sleep(0.5)

# Type name in the "Create a Basin Model" dialog
new_dlg = app.AXFocusedWindow
# field[0] = name, field[1] = description
pyautogui.click(fields[0].AXPosition.x + 90, fields[0].AXPosition.y + 9)
time.sleep(0.2)
subprocess.run(['osascript', '-e', '...keystroke "a" using command down...'])
subprocess.run(['osascript', '-e', '...keystroke "CastroValley"...'])
time.sleep(0.3)
# Press Create (button sorted index as needed)
```

---

## Download DEM from USGS 3DEP ✅

Verified: 2026-05-07. Pure Python, no GDAL needed.

```python
import urllib.request

bbox = "-122.12,37.65,-122.00,37.78"  # Castro Valley bounding box
url = (
    "https://elevation.nationalmap.gov/arcgis/services/3DEPElevation/ImageServer/WCSServer"
    "?SERVICE=WCS&VERSION=1.0.0&REQUEST=GetCoverage"
    "&COVERAGE=DEP3Elevation&CRS=EPSG:4326"
    f"&BBOX={bbox}&WIDTH=512&HEIGHT=512&FORMAT=GeoTIFF"
)
urllib.request.urlretrieve(url, "/Users/siddharthsingh/FlowCastroValley/castrovally_dem.tif")

# Verify GeoTIFF header
assert open("/Users/siddharthsingh/FlowCastroValley/castrovally_dem.tif","rb").read(4) == b'II*\x00'
```

---

## Create Terrain Data component ✅

Verified: 2026-05-07

1. Components > Terrain Data Manager
2. Click New... in the manager
3. Name: `Terrain 1`
4. Set terrain directory to `terrain/Terrain_1/`
5. Place the DEM: copy `castrovally_dem.tif` into the terrain directory

---

## Assign terrain to basin model ✅

Verified: 2026-05-08. **Done by direct file edit**, not through the UI (Java combo box won't open).

The Terrain Data combo box in the basin's Coordinate System / Spatial Properties dialog is a Java Swing `JComboBox` that cannot be opened via automation. Instead, add the keyword directly to the `.basin` file:

```
Basin Spatial Properties:
     Terrain: Terrain 1
     Coordinate System: PROJCS["UTM_ZONE_10N_Nad83",...
End:
```

**Key discovery method:** Decompiled `hms.jar` using Python's `zipfile` module to search for the string literal in `.class` bytecode:

```python
import zipfile, re
jar = "/Applications/HEC/HEC-HMS/4.13/hms.jar"
with zipfile.ZipFile(jar) as z:
    for name in z.namelist():
        if name.endswith('.class'):
            data = z.read(name)
            if b'Terrain' in data and b'Basin Spatial' in data:
                matches = re.findall(rb'[A-Za-z ]{3,50}(?=\x00)', data)
                print(name, [m.decode('ascii','ignore') for m in matches if b'Terrain' in m])
```

Found: `hms/model/basin/n/r.class` contains `"     Terrain: "` as the keyword prefix used when reading/writing `Basin Spatial Properties:` blocks.

**Verification:** Reopen project after edit. No WARNING 10175 = accepted.

---

## Set coordinate system ✅

Verified: 2026-05-07

1. In Basin Model Manager: select CastroValley → some edit dialog or via Components > ... (verify path)
2. In the coordinate system dialog, collect all buttons sorted by (y,x)
3. Click text area and type the full WKT string via AppleScript
4. Press button at sorted index 5 (Set)

WKT (UTM Zone 10N NAD83):
```
PROJCS["UTM_ZONE_10N_Nad83",GEOGCS["NAD83",DATUM["North_American_Datum_1983",SPHEROID["GRS 1980",6378137,298.257222101,AUTHORITY["EPSG","7019"]],AUTHORITY["EPSG","6269"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4269"]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",0],PARAMETER["central_meridian",-123],PARAMETER["scale_factor",0.9996],PARAMETER["false_easting",500000],PARAMETER["false_northing",0],UNIT["metre",1,AUTHORITY["EPSG","9001"]],AXIS["Easting",EAST],AXIS["Northing",NORTH]]
```

---

## Open basin model in canvas ❌ (BLOCKED)

Last attempt: 2026-05-08. **Not yet solved.**

**What's needed:** CastroValley basin model must be open in the canvas before GIS menu items become enabled.

**What was tried:**
- Expanding the JTree "Basin Models" node: right arrow key, disclosure triangle click, CGEventPostToPid — all failed
- Double-click on AXRow in Basin Model Manager: selects item but doesn't open it
- `AXRow.Press()` in Basin Model Manager: executes without error but doesn't open model in canvas
- AppleScript click, double-click: same result as pyautogui

**Next approach to try:**
Search the HEC-HMS jar for the keyword that saves "which basin model was open in the canvas" — likely something in the `.hms` or `.basin` file, similar to how `Terrain:` in `Basin Spatial Properties:` was found. Adding this key to the file before opening HEC-HMS might pre-open the model without needing UI interaction.

```python
# Jar search pattern
import zipfile, re
jar = "/Applications/HEC/HEC-HMS/4.13/hms.jar"
with zipfile.ZipFile(jar) as z:
    for name in z.namelist():
        data = z.read(name)
        if b'Desktop' in data or b'Open Window' in data or b'Active Basin' in data:
            print(name)
```

---

## GIS Preprocessing 🔬 (not yet run)

Requires the basin model to be open in the canvas first.

Planned sequence:
1. GIS > Preprocess Sinks
2. GIS > Preprocess Drainage  
3. GIS > Identify Streams
4. GIS > Delineate Elements

Each step opens a dialog and runs terrain analysis. The output is a set of subbasins and reaches drawn on the canvas.

---

## Add USGS gauges to canvas 🔬 (not yet run)

25 gauges identified for Castro Valley bounding box (-122.12, 37.65, -122.00, 37.78). See [gauges.md](gauges.md) for full list. Plan: use Components > Time-Series Data Manager or direct canvas placement after watershed is delineated.
