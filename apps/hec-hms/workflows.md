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

## Open basin model in canvas ✅

Verified: 2026-05-13. Use AXPress on project tree rows + Enter key.

**Method:** Expand the project tree via `AXUIElementPerformAction(row, 'AXPress')`, select CastroValley, close Basin Model Manager, click the tree row, send Enter. See [java-swing-issues.md](java-swing-issues.md) Issue 3 for the full working code.

**Key insight:** The AXOutline IS exposed in the AX hierarchy — it just lives deep under the main window's AXSplitGroup. Java JTree handles Enter as "activate" which triggers the same code path as double-click. AX `Press` on a tree row toggles expand/collapse.

**Verification:** After running, the GIS menu items transition from disabled → enabled (Preprocess Sinks, Preprocess Drainage, Identify Streams, etc.).

**Gotchas:**
- AXPress on an already-expanded row will COLLAPSE it. Check `rows` count first.
- Match rows by exact `AXDescription` equality, not substring — `'Castro' in desc` will match `FlowCastroValley` (the project root) before `CastroValley` (the basin).
- BMM intercepts Enter key — must close BMM first via clicking the close button at window origin + (7, 14).

---

## GIS Preprocessing ⚠️ (partially working — 2026-05-13)

### Steps 1–3 completed ✅

Terrain preprocessing ran successfully:
- GIS > Preprocess Sinks → filled DEM in `terrain/Terrain_1/01/elevation.tif`
- GIS > Preprocess Drainage → `flowdir.tif`, `flowaccum.tif` (max=3680 = watershed area in pixels)
- GIS > Identify Streams → `str_bin.tif`, `streams.tif` (very low threshold ≈1, 223k stream pixels)

### Step 4: Delineate Elements ⚠️ (outlet fixed, needs re-run)

**Pre-conditions:**
- Place outlet point INSIDE the DEM extent: X must be < 581360, Y must be between 4171986–4181896
- Correct Castro Valley outlet: X=581359.324, Y=4171986.224
- Check current placement: `sqlite3 gis/CastroValley/toGIS.sqlite "SELECT hex(GEOMETRY) FROM breakpoints ORDER BY rowid DESC LIMIT 1;"` → decode bytes 5-21 as two little-endian doubles

**What works:**
- Terrain preprocessing TauDEM steps (flowaccum, threshold) succeed ✅
- subbasin row created in CastroValley.sqlite after delineation ✅

**What fails:**
- Reach creation fails with ERROR 46503 (NPE on SetAttributeFilter)
- Root cause: TauDEM's streamnet produces empty coord.dat when outlet is outside DEM
- After fixing outlet in toGIS.sqlite (rowid=7, X=581359), streamnet SHOULD succeed

**Pre-inject watcher (insurance):**
```bash
# Kill any old watchers first (they may use wrong WKB)
pkill -f delin_watcher
# Start current watcher (plain 2D WKB, 50ms poll)
python3 /tmp/delin_watcher3.py &
```

**Diagnostic: decode all delin dir outlets:**
```python
import struct, sqlite3
from pathlib import Path
for db in sorted(Path('gis/CastroValley').glob('delin_*/fromGIS.sqlite')):
    c = sqlite3.connect(str(db))
    row = c.execute('SELECT hex(GEOMETRY), id FROM breakpoints LIMIT 1').fetchone()
    if row:
        b = bytes.fromhex(row[0])
        x, y = struct.unpack('<2d', b[5:21])
        ok = '✓' if x < 581360 else '✗ OUTSIDE DEM'
        print(f'{db.parent.name}: X={x:.1f} Y={y:.1f} {ok}')
```

---

## Add USGS gauges to canvas 🔬 (not yet run)

25 gauges identified for Castro Valley bounding box (-122.12, 37.65, -122.00, 37.78). See [gauges.md](gauges.md) for full list. Plan: use Components > Time-Series Data Manager or direct canvas placement after watershed is delineated.
