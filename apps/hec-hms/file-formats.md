# HEC-HMS — File Formats

HEC-HMS stores everything as plain-text keyword files. Each file is a series of named blocks:
```
BlockType: BlockName
     KeyWord: Value
     ...
End:
```

All keywords are case-sensitive. Indentation is 5 spaces.

---

## .hms — Project file

Master file that lists all components. Lives at `<ProjectName>.hms`.

```
Project: FlowCastroValley
     Description: 
     Version: 4.13
     Filepath Separator: /
     DSS File Name: FlowCastroValley.dss
     Time Zone ID: America/Los_Angeles
End:

Basin: CastroValley
     Filename: CastroValley.basin
     Description: 
     Last Modified Date: 8 May 2026
     Last Modified Time: 01:13
End:
```

To add more components, add more blocks (e.g., `Met: ...`, `Control: ...`, `Run: ...`).

---

## .basin — Basin model file

Defines a single basin model. Lives at `<BasinName>.basin`.

Key sections:

### Header
```
Basin: CastroValley
     Last Modified Date: 8 May 2026
     Last Modified Time: 01:13:32
     Version: 4.13
     Filepath Separator: /
     Unit System: English
     Missing Flow To Zero: No
     Enable Flow Ratio: No
     Compute Local Flow At Junctions: No
     Unregulated Output Required: No
     Enable Sediment Routing: No
End:
```

### Basin Spatial Properties
Contains terrain assignment and coordinate system:
```
Basin Spatial Properties:
     Terrain: Terrain 1
     Coordinate System: PROJCS["UTM_ZONE_10N_Nad83",...full WKT...]
End:
```

**`Terrain:`** — name of the Terrain Data component to use. Found via jar decompilation in `hms/model/basin/n/r.class`.

### Basin Layer Properties
Empty until GIS preprocessing adds layers:
```
Basin Layer Properties:
End:
```

### Basin Schematic Properties
View settings for the canvas:
```
Basin Schematic Properties:
     Last View N: NaN
     Last View S: NaN
     ...
     Draw Icons: Yes
     Draw Icon Labels: Name
     ...
End:
```

After GIS preprocessing runs, hydrologic elements (subbasins, reaches, junctions, sinks) are appended to this file.

---

## .terrain — Terrain data manager file

Lists all terrain datasets. Lives at `<ProjectName>.terrain`.

```
Terrain Data Manager: FlowCastroValley
     Version: 4.13
     Filepath Separator: /
End:

Terrain Data: Terrain 1
     Description: 
     Terrain Directory: terrain/Terrain_1
     Vertical Units: Meters
     Last Modified Date: 8 May 2026
     Last Modified Time: 01:26:12
End:
```

The `Terrain Directory` is relative to the project folder. The actual DEM file lives inside that directory.

---

## .sqlite — Spatial databases

HEC-HMS uses several SQLite spatial databases. These are **NOT** standard SpatiaLite — they use a custom 6-column `geometry_columns` format.

### CastroValley.sqlite — basin element output

Written to by HEC-HMS after successful Delineate Elements. Lives at project root.

Tables populated after delineation:
- `subbasin2d` / `subbasin` — polygon + attribute rows per subbasin
- `reach2d` / `reach` — linestring + attribute rows per reach
- `junction`, `sink`, etc. — point elements
- `geometry_columns`, `spatial_ref_sys` — spatial metadata

**Inspect:**
```python
import sqlite3
conn = sqlite3.connect('/Users/siddharthsingh/FlowCastroValley/CastroValley.sqlite')
tables = conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
for t in tables:
    count = conn.execute(f'SELECT COUNT(*) FROM "{t[0]}"').fetchone()[0]
    print(t[0], count)
```

### fromGIS.sqlite — GIS input data

Lives at `gis/CastroValley/fromGIS.sqlite` (MAIN) and in each `delin_*/fromGIS.sqlite`.

The MAIN file holds pre-processed watershed data that we inject. Delin dir files are per-run scratch databases created by HEC-HMS.

**geometry_columns schema (HEC-HMS custom — 6 columns, not standard SpatiaLite):**
```sql
CREATE TABLE geometry_columns (
    f_table_name VARCHAR,
    f_geometry_column VARCHAR,
    geometry_type INTEGER,   -- 1=Point, 2=LineString, 3=Polygon, 6=MultiPolygon
    coord_dimension INTEGER, -- 2=2D
    srid INTEGER,
    geometry_format VARCHAR  -- always 'WKB'
);
```

**reach_raw** (geometry_type=2, WKB 2D LineString `0x00000002`):
- Fields: linkno, dslinkno, uslinkno1, uslinkno2, dsnodeid, strmorder, length, magnitude, dscontarea, strmdrop, slope, straightl, uscontarea, wsno, doutend, doutstart, doutmid
- Source: TauDEM net.shp (populated by HEC-HMS after TauDEM, or pre-injected by watcher)

**subbasin** (geometry_type=6, WKB 2D MultiPolygon `0x00000006`):
- Fields: basinid, centroid_x, centroid_y, area_sqkm, latitude, longitude
- Source: ws_ids.tif raster, ws_id=2 = 3,680 pixels built into 183 rectangular polygons

**breakpoints** (geometry_type=1, Extended WKB Point with M `0x80000001`):
- Fields: id
- Contains user-placed outlet point (copied from toGIS.sqlite by HEC-HMS at delineation start)
- ⚠️ Created WITHOUT `IF NOT EXISTS` — pre-creating this table will cause HEC-HMS to error

### toGIS.sqlite — user outlet placement

Lives at `gis/CastroValley/toGIS.sqlite`. Stores the outlet point the user places on the map.

```sql
CREATE TABLE IF NOT EXISTS 'breakpoints' (
    "ogc_fid" INTEGER PRIMARY KEY AUTOINCREMENT,
    'GEOMETRY' BLOB   -- Extended WKB Point with M (0x80000001): struct.pack('<BIddd', 1, 0x80000001, x, y, 0.0)
);
```

Check current outlet:
```python
import struct, sqlite3
c = sqlite3.connect('.../gis/CastroValley/toGIS.sqlite')
h = c.execute('SELECT hex(GEOMETRY) FROM breakpoints ORDER BY rowid DESC LIMIT 1').fetchone()[0]
b = bytes.fromhex(h)
x, y = struct.unpack('<2d', b[5:21])
print(f'Outlet: X={x:.3f}, Y={y:.3f}')
# Castro Valley correct outlet: X=581359.324, Y=4171986.224 (SE corner of DEM, inside extent)
# WRONG outlet: X>581360 is OUTSIDE the DEM → TauDEM streamnet fails → coord.dat=0 bytes → ERROR 46503
```

---

## .dss — HEC-DSS data store

Binary HEC-DSS format for time-series data (streamflow records, precipitation). Not human-readable. Use HEC-DSSVue to inspect. Lives at `<ProjectName>.dss`.

---

## .access — Project access control

Zero-byte file in current project. Purpose unclear — possibly a lock file or legacy feature.

---

## basinStates/ directory

Stores basin model state between sessions. Currently empty (no simulation runs have been computed yet).

---

## terrain/ directory

```
terrain/
  Terrain_1/
    <DEM files>   ← castrovally_dem.tif placed here
```

The `.terrain` file's `Terrain Directory: terrain/Terrain_1` points here (relative path from project root).
