# HEC-HMS — GIS Preprocessing Workflow

## Prerequisites

Before running GIS preprocessing:
- ✅ Basin model (CastroValley) must be open in the canvas
- ✅ Terrain Data (Terrain 1) must be assigned to the basin
- ✅ Coordinate system must be set (UTM Zone 10N NAD83)
- ❌ Currently blocked: cannot open basin model in canvas (see [java-swing-issues.md](java-swing-issues.md))

## DEM Details

| Property | Value |
|----------|-------|
| Source | USGS 3DEP 1/3 arc-second NED |
| Coverage | Castro Valley, CA |
| Bounding box | -122.12°W, 37.65°N to -122.00°W, 37.78°N |
| Resolution | 512 × 512 pixels |
| File | `castrovally_dem.tif` (1.0 MB GeoTIFF) |
| CRS | EPSG:4326 (downloaded), converted to EPSG:26910 by HEC-HMS |
| Terrain dir | `terrain/Terrain_1/` |

## Step 1 — Preprocess Sinks

**Menu:** GIS > Preprocess Sinks

Fills depressions in the DEM so flow can route continuously downslope. Opens a dialog with DEM layer selection and sink fill options. Accept defaults for most cases.

Expected output: a "filled DEM" layer added to the terrain.

## Step 2 — Preprocess Drainage

**Menu:** GIS > Preprocess Drainage

Computes flow direction and flow accumulation grids from the filled DEM.

Expected output: flow direction and accumulation layers.

## Step 3 — Identify Streams

**Menu:** GIS > Identify Streams

Define the stream network by setting an accumulation threshold. Lower threshold = more streams / smaller subbasins.

**For Castro Valley:** Start with a threshold of ~1000 cells (small watershed, want decent resolution).

Expected output: stream network layer displayed on canvas.

## Step 4 — Delineate Elements

**Menu:** GIS > Delineate Elements

HEC-HMS automatically delineates:
- **Subbasins** — drainage area polygons
- **Reaches** — stream segments
- **Junctions** — confluence points
- **Sink** — outlet point (usually at the bottom of the watershed)

These elements appear as icons on the canvas and get written to `CastroValley.sqlite`.

## Step 5 — Review and clean up

After delineation:
1. Check the canvas to confirm subbasins cover the Castro Valley drainage area
2. Verify the outlet (sink) is at the right location
3. Add any missing breakpoints (GIS > Break Points Manager) before re-delineating if needed

## Planned: Add USGS gauges

After delineation, add the 25 USGS NWIS stream and rain gauges as meteorological or discharge elements. See [gauges.md](gauges.md).

## Jar decompilation for GIS key discovery

The same method used to find `Terrain:` can be used to find the exact keywords for GIS layers and element delineation outputs:

```python
import zipfile, re
jar = "/Applications/HEC/HEC-HMS/4.13/hms.jar"
with zipfile.ZipFile(jar) as z:
    for name in z.namelist():
        if name.endswith('.class'):
            data = z.read(name)
            if b'Preprocess' in data or b'Delineate' in data:
                print(name)
```
