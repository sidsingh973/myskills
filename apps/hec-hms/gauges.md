# HEC-HMS — Castro Valley USGS NWIS Gauges

## Bounding box

`-122.12, 37.65, -122.00, 37.78` (W, S, E, N)

## Fetch command

```python
import urllib.request, json

bbox = "-122.12,37.65,-122.00,37.78"
url = (
    "https://waterservices.usgs.gov/nwis/site/"
    f"?format=rdb&bBox={bbox}"
    "&siteType=ST,AT"          # ST=stream, AT=atmosphere/rain
    "&siteStatus=all"
    "&hasDataTypeCd=dv,iv"
)
with urllib.request.urlopen(url) as r:
    data = r.read().decode('utf-8')
# Parse RDB format (tab-separated, skip lines starting with #)
```

## Stream gauges (ST)

| Site No | Name | Lat | Lon |
|---------|------|-----|-----|
| 11181004 | CASTRO VALLEY C A CASTRO VALLEY CA | 37.71 | -122.06 |
| 11181006 | Castro Valley C at Knox St | ~37.71 | ~-122.06 |
| 11181008 | Castro Valley C at Hayward | ~37.70 | ~-122.08 |

(Full list of 25 sites was fetched — rebuild by re-running the NWIS query above)

## Rain gauges (AT)

Atmospheric sites in the bounding box include:
- Sydney School rain gauge
- Proctor School rain gauge  
- Joseph Avenue rain gauge

(Exact site numbers: re-run the NWIS query with `siteType=AT`)

## Adding to HEC-HMS

After GIS delineation, attach gauge data as time-series:

1. **Components > Time-Series Data Manager** → New → set site number and parameter
2. Or: place them on the canvas as Meteorological elements and link to subbasins

For each stream gauge: create a Subbasin or Junction element near the gauge location and associate it as a "discharge measurement point."

For each rain gauge: create a Meteorological Model that uses the gauge's precipitation record.

## Data access

Historical data for any USGS site:
```python
site = "11181004"
url = (
    f"https://waterservices.usgs.gov/nwis/dv/"
    f"?format=json&sites={site}"
    "&parameterCd=00060"        # 00060 = discharge (cfs)
    "&startDT=2020-01-01&endDT=2024-12-31"
)
```

Precipitation (parameterCd=00045) for rain gauges:
```python
url = (
    f"https://waterservices.usgs.gov/nwis/iv/"
    f"?format=json&sites={site}"
    "&parameterCd=00045"        # 00045 = precipitation (inches)
    "&startDT=2020-01-01&endDT=2024-12-31"
)
```
