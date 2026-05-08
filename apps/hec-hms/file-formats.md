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

## .sqlite — Spatial database

`<BasinName>.sqlite` is a SpatiaLite database (SQLite + spatial extensions). Stores the geometry for all hydrologic elements once they're delineated.

**Tables:**
- `subbasin` — polygon geometries for each subbasin
- `reach` — polyline geometries for stream reaches
- `junction` — point geometries for junctions
- `reservoir` — point geometries
- `source`, `diversion`, `sink`, `outlet` — point geometries
- `subbasin2d`, `reach2d`, `reservoir2d` — 2D versions
- `geometry_columns` — SpatiaLite metadata
- `spatial_ref_sys` — CRS definition (SRID 26910 = UTM Zone 10N NAD83)

All tables are empty until GIS preprocessing runs and Delineate Elements is executed.

**Inspect:**
```python
import sqlite3
conn = sqlite3.connect('/Users/siddharthsingh/FlowCastroValley/CastroValley.sqlite')
tables = conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()
for t in tables:
    count = conn.execute(f'SELECT COUNT(*) FROM "{t[0]}"').fetchone()[0]
    print(t[0], count)
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
