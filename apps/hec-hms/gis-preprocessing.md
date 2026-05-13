# HEC-HMS — GIS Preprocessing & Delineate Elements

## Prerequisites

- ✅ Basin model (CastroValley) open in canvas (Terrain: Terrain 1 in .basin file)
- ✅ Terrain preprocessed (GIS > Preprocess Sinks → Drainage → Identify Streams)
- ✅ Outlet point placed on map (stored in `toGIS.sqlite`)

---

## Castro Valley Watershed — Key Constants

```python
ORIGIN_X  = 574851.0          # UTM 26910 west edge of raster
ORIGIN_Y  = 4181896.0         # UTM 26910 north edge of raster
dx        = 30.919293          # m/pixel (east)
dy        = 30.919455          # m/pixel (south)
# Pixel size derived from: outlet pixel (210.5, 320.5) → UTM (581359.323527, 4171986.224491)
# dx = (581359.323527 - 574851.0) / 210.5
# dy = (4181896.0 - 4171986.224491) / 320.5

OUTLET_X  = 581359.324        # UTM easting of watershed outlet (SE corner of DEM)
OUTLET_Y  = 4171986.224       # UTM northing
# This is the CORRECT outlet. Placing it outside X > 581360 breaks TauDEM (see §Delineate Elements).

SRID      = 26910              # UTM Zone 10N NAD83
```

---

## Terrain preprocessing outputs

After GIS > Preprocess Drainage, stored in `terrain/Terrain_1/01/`:

| File | Description | Notes |
|------|-------------|-------|
| `elevation.tif` | Pit-filled DEM | 489×471 px, F (float32) |
| `flowdir.tif` | D8 flow direction | 489×471 px |
| `flowaccum.tif` | D8 flow accumulation | max = 3680 (= watershed pixel count) |
| `str_bin.tif` | Binary stream grid | 223,346 stream pixels — HEC-HMS uses low threshold ≈1 here |
| `streams.tif` | Stream mask | Same pixel count as str_bin.tif |

The terrain `flowaccum.tif` has max=3680 (the total watershed area in pixels). Correct.

---

## Manual TauDEM reference outputs (`/tmp/taudem_out/`)

Run manually with threshold=1500 cells. These match the reach_raw rows we inject.

| File | Description |
|------|-------------|
| `net_1500.shp/dbf` | 5 stream links (linkno 0–4) |
| `coord_1500.dat` | 165 coordinate points |
| `tree_1500.dat` | Link topology: {4:(0,4), 3:(5,26), 2:(27,134), 1:(135,141), 0:(142,164)} |
| `ws_ids_1500.tif` | Watershed IDs — ws_id=2 = 3,680 pixels = 3.52 km² |

DBF fields → SQLite column mapping:
```python
DBF2SQL = {
    'LINKNO':'linkno', 'DSLINKNO':'dslinkno', 'USLINKNO1':'uslinkno1', 'USLINKNO2':'uslinkno2',
    'DSNODEID':'dsnodeid', 'strmOrder':'strmorder', 'Length':'length', 'Magnitude':'magnitude',
    'DSContArea':'dscontarea', 'strmDrop':'strmdrop', 'Slope':'slope', 'StraightL':'straightl',
    'USContArea':'uscontarea', 'WSNO':'wsno', 'DOUTEND':'doutend', 'DOUTSTART':'doutstart',
    'DOUTMID':'doutmid'
}
INT_FIELDS = {'LINKNO','DSLINKNO','USLINKNO1','USLINKNO2','DSNODEID','strmOrder','Magnitude','WSNO'}
```

---

## Delineate Elements — internal flow

When user clicks **GIS > Delineate Elements**:

1. HEC-HMS reads outlet from `gis/CastroValley/toGIS.sqlite` (breakpoints table)
2. Creates `gis/CastroValley/delin_YYMMDDHHMMSSMMM/` directory
3. Creates `delin_dir/fromGIS.sqlite` with FULL schema (see §fromGIS.sqlite schema below)
4. Copies outlet into `delin_dir/fromGIS.sqlite` breakpoints (adds `id` column = 1)
5. Runs TauDEM: flowaccum → threshold → moveoutletstostrm → streamnet
6. TauDEM writes into delin_dir: `flowaccum.tif`, `str_bin.tif`, `streams.tif`, `strord.tif`, `ws_ids.tif`, `coord.dat`, `linktree.dat`, `net.shp`
7. If TauDEM succeeds: HEC-HMS uses GDAL to write stream segments to `delin_dir/fromGIS.sqlite` reach_raw
8. HEC-HMS reads reach_raw + subbasin via GDAL (GetLayerByName) to create elements in `CastroValley.sqlite`

### Key GDAL classes in hms.jar

| Class | Role |
|-------|------|
| `hms/b/b/a.class` | Orchestrator: opens delin GDAL DataSource, runs TauDEM, reads net.shp |
| `hms/b/b/e.class` | Reach topology processor: receives Layer from a.class, calls SetAttributeFilter |
| `hms/b/b/c.class` | DataSource management (open/create) |
| `hms/b/b/d.class` | Raster processing (flow accumulation grids) |
| `hms/b/j.class` | Subbasin element creation: reads subbasin, writes to CastroValley.sqlite (subbasin2d, reach2d) |

---

## ERROR 46503 — Root cause analysis

```
ERROR: Cannot invoke "org.gdal.ogr.Layer.SetAttributeFilter(String)" because "this.b" is null
ERROR: ERROR 46503: An error occurred during delineation. Contact HEC for assistance.
```

**Cause chain:**
1. `b` is field of type `org.gdal.ogr.Layer` in `hms/b/b/e.class`
2. `b` is null because `GetLayerByName("reach_raw")` returned Java null
3. `null.SetAttributeFilter(...)` throws NullPointerException
4. HEC-HMS catches it as ERROR 46503

**Root cause found: outlet point outside DEM extent**
- DEM extent: X from 574851 to 581360, Y from 4171986 to 4181896
- Early delineation attempts had outlet at **X=581977, Y=4172944** (617m east of DEM boundary)
- TauDEM's moveoutletstostrm couldn't snap → streamnet produced empty `coord.dat` (0 bytes)
- When TauDEM fails, HEC-HMS tries GDAL fallback → GetLayerByName("reach_raw") → null → NPE

**Current state (outlet fixed):**
- `toGIS.sqlite` now has correct outlet at **(581359.324, 4171986.224)** (rowid=7, latest placement)
- Future delineation should work if TauDEM threshold is compatible

**Evidence:**
- `CastroValley.sqlite` has subbasin2d=1 row (HEC-HMS DID read our subbasin ✓)
- `CastroValley.sqlite` has reach2d=0 rows (reach creation failed due to NPE)

---

## fromGIS.sqlite schema

**Both** `gis/CastroValley/fromGIS.sqlite` (MAIN) and `delin_*/fromGIS.sqlite` use this schema. HEC-HMS creates it. IMPORTANT: the extra `geometry_format VARCHAR` column in geometry_columns is HEC-HMS's custom extension — not standard SpatiaLite.

```sql
CREATE TABLE geometry_columns (
    f_table_name VARCHAR,
    f_geometry_column VARCHAR,
    geometry_type INTEGER,      -- OGC WKB type: 1=Point, 2=LineString, 6=MultiPolygon
    coord_dimension INTEGER,    -- 2 for 2D, 3 for 3D
    srid INTEGER,
    geometry_format VARCHAR     -- always 'WKB'
);

CREATE TABLE spatial_ref_sys (
    srid INTEGER UNIQUE,
    auth_name TEXT,
    auth_srid TEXT,
    srtext TEXT
);

-- HEC-HMS creates with CREATE TABLE (no IF NOT EXISTS!) — pre-existing table causes error
CREATE TABLE 'breakpoints' (
    "ogc_fid" INTEGER PRIMARY KEY AUTOINCREMENT,
    'GEOMETRY' BLOB,
    'id' INTEGER
);

-- HEC-HMS creates with CREATE TABLE IF NOT EXISTS — safe to pre-create
CREATE TABLE IF NOT EXISTS 'reach_raw' (
    "ogc_fid" INTEGER PRIMARY KEY AUTOINCREMENT,
    'GEOMETRY' BLOB,
    'linkno' INTEGER, 'dslinkno' INTEGER, 'uslinkno1' INTEGER, 'uslinkno2' INTEGER,
    'dsnodeid' INTEGER, 'strmorder' INTEGER, 'length' FLOAT, 'magnitude' INTEGER,
    'dscontarea' FLOAT, 'strmdrop' FLOAT, 'slope' FLOAT, 'straightl' FLOAT,
    'uscontarea' FLOAT, 'wsno' INTEGER, 'doutend' FLOAT, 'doutstart' FLOAT, 'doutmid' FLOAT
);

-- HEC-HMS creates with CREATE TABLE IF NOT EXISTS — safe to pre-create
CREATE TABLE IF NOT EXISTS 'subbasin' (
    "ogc_fid" INTEGER PRIMARY KEY AUTOINCREMENT,
    'GEOMETRY' BLOB,
    'basinid' INTEGER, 'centroid_x' FLOAT, 'centroid_y' FLOAT,
    'area_sqkm' FLOAT, 'latitude' FLOAT, 'longitude' FLOAT
);
```

**geometry_columns entries:**
```
breakpoints | GEOMETRY | 1 | 2 | 26910 | WKB
reach_raw   | GEOMETRY | 2 | 2 | 26910 | WKB
subbasin    | GEOMETRY | 6 | 2 | 26910 | WKB
```

All three rows are inserted by HEC-HMS in a single transaction at delin dir init time (rowids 1, 2, 3).

---

## toGIS.sqlite — outlet placement

`gis/CastroValley/toGIS.sqlite` stores the user-placed outlet points. Different from delin dir's breakpoints (no `id` column):

```sql
CREATE TABLE IF NOT EXISTS 'breakpoints' (
    "ogc_fid" INTEGER PRIMARY KEY AUTOINCREMENT,
    'GEOMETRY' BLOB  -- Extended WKB Point with M (type=0x80000001)
);
```

Latest outlet (rowid=7): **X=581359.324, Y=4171986.224** — correct watershed outlet.

To decode the outlet:
```python
import struct, sqlite3
conn = sqlite3.connect('.../toGIS.sqlite')
h = conn.execute('SELECT hex(GEOMETRY) FROM breakpoints ORDER BY rowid DESC LIMIT 1').fetchone()[0]
b = bytes.fromhex(h)
wkb_type = struct.unpack('<I', b[1:5])[0]  # 0x80000001 = Extended WKB Point with M
x, y = struct.unpack('<2d', b[5:21])       # 21-29 bytes = M coordinate (0.0)
```

---

## WKB encoding for geometry types

**Outlet Point (type 0x80000001 = Extended WKB with M):**
```python
struct.pack('<BIddd', 1, 0x80000001, x, y, 0.0)
```

**reach_raw LineString (type 0x00000002 = plain 2D WKB) — CORRECT for HEC-HMS:**
```python
buf = struct.pack('<BI', 1, 2) + struct.pack('<I', n)
for x, y in pts: buf += struct.pack('<2d', x, y)
```
⚠️ Do NOT use Extended WKB (0x80000002 / 3D with M). GDAL rejects it.

**subbasin MultiPolygon (type 0x00000006 = plain 2D WKB) — verified working:**
```python
# One polygon per horizontal pixel run from ws_ids raster
def ring(cs, ce, row):
    xl = ORIGIN_X + cs*dx; xr = ORIGIN_X + (ce+1)*dx
    yt = ORIGIN_Y - row*dy; yb = ORIGIN_Y - (row+1)*dy
    return [(xl,yt),(xr,yt),(xr,yb),(xl,yb),(xl,yt)]

def wkb_multipolygon(polys):  # polys = list of [ring]
    parts = []
    for rings in polys:
        pb = struct.pack('<BI', 1, 3) + struct.pack('<I', len(rings))
        for rg in rings: pb += struct.pack('<I', len(rg)) + b''.join(struct.pack('<2d',x,y) for x,y in rg)
        parts.append(pb)
    return struct.pack('<BI', 1, 6) + struct.pack('<I', len(parts)) + b''.join(parts)
```

---

## Watcher script for injecting reach/subbasin

`/tmp/delin_watcher3.py` watches for new `delin_*/fromGIS.sqlite` and injects data.

**Critical:** Kill the OLD `/tmp/delin_watcher.py` (Extended WKB) before starting:
```bash
pkill -f delin_watcher.py  # kill all watchers
python3 /tmp/delin_watcher3.py &
```

The watcher polls every 50ms. After detecting new SQLite: deletes existing rows, inserts 5 reach_raw rows (plain 2D WKB) and 1 subbasin row.

**Remaining GDAL issue (open):** Even with correct WKB in reach_raw, `GetLayerByName("reach_raw")` sometimes returns null. Root cause: GDAL may open the DataSource before the geometry_columns entries are committed. Potential fix: watch for delin DIRECTORY creation (not file) and pre-create fromGIS.sqlite before HEC-HMS opens it.

---

## CastroValley.sqlite — final output

Written by HEC-HMS after successful delineation:

| Table | When populated | Notes |
|-------|----------------|-------|
| `subbasin2d` | After subbasin created | MultiPolygon WKB |
| `reach2d` | After reach created | LineString WKB |
| `subbasin` | After subbasin created | Non-spatial attrs |
| `reach` | After reach created | Non-spatial attrs |

**Verify:**
```python
import sqlite3
c = sqlite3.connect('/Users/siddharthsingh/FlowCastroValley/CastroValley.sqlite')
for t in ['subbasin2d','reach2d','subbasin','reach']:
    print(t, c.execute(f'SELECT COUNT(*) FROM {t}').fetchone()[0])
```

Expected after successful delineation: subbasin2d≥1, reach2d≥1.

---

## jar decompilation for debugging

```python
import zipfile, re
jar = "/Applications/HEC-HMS-4.13.app/Contents/Resources/hms.jar"
with zipfile.ZipFile(jar) as z:
    for name in sorted(z.namelist()):
        if name.startswith('hms/b/b/') and name.endswith('.class'):
            data = z.read(name)
            strings = [s.decode() for s in re.findall(rb'[\x20-\x7e]{4,}', data)]
            useful = [s for s in strings if any(k in s.lower() for k in
                      ['reach','subbasin','linkno','layer','filter','error','taudem'])]
            if useful:
                print(f'=== {name} ===')
                for s in useful: print(' ', s)
```

Key strings found in `hms/b/b/a.class`: `reach_raw`, `subbasin`, `delin_`, `breakpoints`, `polygonize_output`, `"TauDEM stream network layer not found."`, `"Unable to access user break point layer breakpoints"`
