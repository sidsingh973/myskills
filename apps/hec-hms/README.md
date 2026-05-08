# HEC-HMS 4.13

HEC-HMS (Hydrologic Engineering Center – Hydrologic Modeling System) is the USACE (US Army Corps of Engineers) software for simulating rainfall-runoff processes in dendritic watershed systems.

Used here for: **Castro Valley watershed delineation and gauge marking** on Siddharth's Mac (macOS Sequoia 15.x, Darwin 25.x).

## Files in this folder

| File | What it covers |
|------|---------------|
| [ax-map.md](ax-map.md) | All AX element positions, button indices, dialog layouts |
| [workflows.md](workflows.md) | Step-by-step verified workflows |
| [file-formats.md](file-formats.md) | .hms, .basin, .terrain, .sqlite — structure and editing |
| [java-swing-issues.md](java-swing-issues.md) | HEC-HMS-specific Java Swing failures and workarounds |
| [gis-preprocessing.md](gis-preprocessing.md) | GIS terrain preprocessing workflow (planned) |
| [gauges.md](gauges.md) | USGS NWIS gauges for Castro Valley |

Also see the main app knowledge JSON: [../HEC-HMS.json](../HEC-HMS.json)

## Version

HEC-HMS 4.13 — Java Swing app running under macOS JVM  
AX process name: `HEC-HMS-4.13`  
Project path: `/Users/siddharthsingh/FlowCastroValley/`

## Project: FlowCastroValley

| Component | Name | File |
|-----------|------|------|
| Basin Model | CastroValley | `CastroValley.basin` |
| Terrain Data | Terrain 1 | `terrain/Terrain_1/` (DEM source: USGS 3DEP) |
| Spatial DB | — | `CastroValley.sqlite` |

**Coordinate system:** UTM Zone 10N, NAD83 (EPSG:26910)  
**Unit system:** English

## Current status (as of 2026-05-07)

- ✅ Project created
- ✅ Basin model CastroValley created
- ✅ DEM downloaded (`castrovally_dem.tif`, USGS 3DEP WCS, 512×512)
- ✅ Terrain 1 created pointing to DEM
- ✅ Terrain 1 assigned to CastroValley basin (via `.basin` file edit)
- ✅ Coordinate system set to UTM Zone 10N NAD83
- ❌ Basin model NOT yet open in canvas (JTree won't expand via automation)
- ❌ GIS preprocessing not yet run (requires active basin model in canvas)
- ❌ USGS gauges not yet added to canvas
