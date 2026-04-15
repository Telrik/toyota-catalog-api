# Toyota Catalog Identification API

This workspace contains an OpenAPI specification for a compact Toyota catalog identification API inspired by the ToyoDIY vehicle identification and parts catalog flow.

The current spec is `toyota.catalog.json`, a compact OpenAPI spec at version `1.1.0`.

The API is designed for a UI that first identifies a vehicle, then opens a vehicle catalog with category tabs and diagram tiles.

## Main Flow

1. Search directly by VIN or frame value using `/identify`.
2. If the VIN/frame search is not exact, use `/selector`.
3. Call `/selector` with no params to get regions.
4. Call `/selector?region=EU` to get years for that region.
5. Call `/selector?region=EU&year=2006` to get models for that region and year.
6. Call `/selector?region=EU&year=2006&model=COROLLA` to get model-code rows and dynamic vehicle-characteristic filters.
7. Optionally refine model-code rows with `params`, for example `grade:SOL,body:SED,engine:1NDTV`.
8. Once `region`, `year`, `model`, and `modelCode` are known, call `/vehicle` to get catalog categories and diagrams.

## Endpoints

### `GET /identify`

Searches from the single text field shown on the identification page.

The request has one required query parameter:

- `vin` - accepts either a VIN or a frame value

Example:

```http
GET /identify?vin=LVGC616Z8NG101242
```

Frame values can be sent through the same field:

```http
GET /identify?vin=ACV40-101242
```

Response shape:

```json
{
  "vin": "LVGC616Z8NG101242",
  "items": [
    {
      "vin": "LVGC616Z8NG101242",
      "modelCode": "C616Z-EXAMPLE",
      "from": "2021-01",
      "to": "2024-12",
      "frame": "C616Z",
      "characteristics": "PARTIAL VIN DECODE"
    }
  ]
}
```

If the VIN or frame value is fully decoded, `items` contains the matching model-code row or rows. If the value is only partially decoded, `items` contains all possible model-code rows for that identifier. If nothing is found, `items` is an empty array.

### `GET /selector`

Drives the progressive vehicle selector.

All selector parameters are optional:

- `region`
- `year`
- `model`
- `params`

The first three are the main selector chain. `params` is for extra vehicle-characteristic filters that vary by model, such as grade, body, engine, transmission, driver position, fuel system, gear shift type, and number of doors.

#### No Parameters

Returns the available regions.

```http
GET /selector
```

Example response:

```json
{
  "selected": {},
  "next": "region",
  "options": [
    { "value": "NA", "label": "North America" },
    { "value": "EU", "label": "Europe" },
    { "value": "JP", "label": "Japan" },
    { "value": "OTHER", "label": "Other" }
  ],
  "filters": [],
  "items": []
}
```

#### Region Selected

Returns years for the selected region.

```http
GET /selector?region=EU
```

The response has `next: "year"` and `options` contains year values.

#### Region And Year Selected

Returns models for that region and year.

```http
GET /selector?region=EU&year=2006
```

Example model option:

```json
{
  "value": "COROLLA",
  "label": "COROLLA",
  "hint": "NDE120,NZE120,ZZE12..."
}
```

The `hint` field is for frame-code text shown beside model links in the UI.

#### Region, Year, And Model Selected

Returns model-code rows plus dynamic characteristic filters.

```http
GET /selector?region=EU&year=2006&model=COROLLA
```

At this stage:

- `next` is `null`
- `options` is empty
- `filters` contains variable filter blocks
- `items` contains model-code rows

Example filter block:

```json
{
  "code": "engine",
  "label": "ENGINE",
  "options": [
    { "value": "1NDTV", "label": "1NDTV: 2000CC DIESEL TURBO" },
    { "value": "1CDTV", "label": "1CDTV: 2000CC DIESEL TURBO" },
    { "value": "3ZZFE", "label": "3ZZFE: 1600CC 16-VALVE DOHC EFI" }
  ]
}
```

Example model-code row:

```json
{
  "vin": "JTDBC20..",
  "modelCode": "NDE120L-AHDYW",
  "from": "2004-08",
  "to": "2006-09",
  "frame": "NDE120",
  "characteristics": "TERRA JPP EUR SED LHD 1NDTV DCR MTM 5F"
}
```

#### Refining With Dynamic Params

Characteristic filters can be selected with the `params` query string.

```http
GET /selector?region=EU&year=2006&model=COROLLA&params=grade:SOL,body:SED,engine:1NDTV
```

The API should use these values to narrow:

- returned filter options
- returned model-code rows

The spec leaves `params` as a compact string because the available filters are not fixed. Different vehicles can expose different groups.

### `GET /vehicle`

Loads the catalog page after a model-code row has been chosen.

Required query parameters:

- `region`
- `year`
- `model`
- `modelCode`

Optional query parameter:

- `categoryId` - integer category id, defaults to `1`

Example:

```http
GET /vehicle?region=EU&year=2006&model=COROLLA&modelCode=NDE120L-AHDYW
```

To open another category:

```http
GET /vehicle?region=EU&year=2006&model=COROLLA&modelCode=NDE120L-AHDYW&categoryId=4
```

Response shape:

```json
{
  "selected": {
    "region": "EU",
    "year": 2006,
    "model": "COROLLA",
    "modelCode": "NDE120L-AHDYW",
    "categoryId": 1
  },
  "categories": [
    {
      "categoryId": 1,
      "label": "Engine / Fuel",
      "groups": ["Engine", "Water pump", "Radiator", "Alternator", "Starter", "Intake", "Exhaust", "Ignition", "Injection"]
    }
  ],
  "diagrams": [
    {
      "diagramId": 1102,
      "name": "Partial Engine Assembly",
      "url": "EU.1993.TOYOTA_COROLLA.CE100L-AWMRSW.1102.html",
      "image": "https://api.example.com/images/toyota/engine-fuel-partial-engine-assembly.png"
    }
  ]
}
```

`diagramId` is an integer, such as `1102`. `url` is the full diagram page URL/path, for example `EU.1993.TOYOTA_COROLLA.CE100L-AWMRSW.1102.html`. `image` is the preview image used for the diagram tile.

## Catalog Categories

The `/vehicle` response includes these top-level category tabs:

- `1` - Engine / Fuel
- `2` - Powertrain / Chassis
- `3` - Body
- `4` - Electrical

Each category includes group labels used by the UI.

Engine / Fuel:

- Engine
- Water pump
- Radiator
- Alternator
- Starter
- Intake
- Exhaust
- Ignition
- Injection

Powertrain / Chassis:

- Transmission
- Driveshaft
- Axle
- Wheels
- Brakes
- Steering
- Suspension

Body:

- Doors
- Windows
- Bumper
- Fuel tank
- Interior
- Seats
- Handles

Electrical:

- Battery
- Air conditioning
- Lights
- Audio
- Airbag
- Mirror

## Validation

The OpenAPI file was validated with:

```powershell
python -m openapi_spec_validator .\toyota.catalog.json
```

Expected result:

```text
.\toyota.catalog.json: OK
```
