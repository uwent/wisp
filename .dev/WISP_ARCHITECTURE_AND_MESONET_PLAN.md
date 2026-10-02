# WISP Architecture & Mesonet Implementation Plan

**Wisconsin Irrigation Scheduling Program (WISP)**
*Architecture reference and implementation guide for external teams*

---

## Abbreviations & Definitions

| Abbreviation | Full Term | Definition |
|-------------|-----------|------------|
| AD | Allowable Depletion | Running daily measure of how much water has been depleted from the root zone relative to field capacity, in inches. Positive = water available; zero or negative = irrigation needed. Also called RAW (Readily Available Water). |
| AD_max | Maximum Allowable Depletion | The depletion threshold at which irrigation should be triggered. Equals MAD × TAW. |
| DD | Deep Drainage | Water that has percolated below the root zone because inputs (rain + irrigation) exceeded field capacity. Lost from the plant-available water budget. |
| ET | Evapotranspiration | Combined water loss from soil evaporation and plant transpiration. Measured in inches/day. |
| ETo / ref_ET | Reference Evapotranspiration | Standardized ET for a hypothetical short grass reference surface under well-watered conditions. Provided by ag-weather stations. Actual crop ET is derived by applying a crop coefficient. |
| adj_ET | Adjusted ET | The actual estimated crop water use for a given day, calculated by scaling ref_ET by a crop coefficient based on canopy cover or LAI. |
| FC | Field Capacity | The fraction of soil volume occupied by water after excess has drained (approximately 24–48 hrs after saturation). Upper bound of plant-available water. |
| Kc | Crop Coefficient | Dimensionless multiplier applied to ref_ET to estimate crop-specific water use. Derived from canopy cover (percent cover method) or leaf area index (LAI method). |
| LAI | Leaf Area Index | Ratio of total one-sided leaf area to ground surface area. Dimensionless. Used to compute Kc via Beer's law: Kc = 1.1 × (1 − e^(−1.5 × LAI)). |
| MAD | Maximum Allowable Depletion | The fraction of TAW that can be depleted before irrigation stress occurs. Default is 0.50 (50%). Crop- and grower-specific. |
| MRZD | Managed Root Zone Depth | The effective depth of the active crop root zone, in inches. Determines how large the water reservoir is. |
| pct_cover | Percent Canopy Cover | The fraction of the ground shaded by the crop canopy, expressed as 0–100%. Used as the primary input to the percent cover ET method. |
| PWP | Permanent Wilting Point | The soil moisture fraction below which plants can no longer extract water. Sets the lower bound of plant-available water. |
| RAW | Readily Available Water | Synonym for AD_max (Allowable Depletion). The portion of TAW that can be used before irrigation stress. |
| TAW | Total Available Water | Total inches of plant-available water in the root zone between field capacity and permanent wilting point. TAW = (FC − PWP) × MRZD. |
| WISP | Wisconsin Irrigation Scheduling Program | The UW-Madison web application this document describes. |

---

## Part 1: WISP Architecture

### Overview

WISP implements the **checkbook method** of irrigation scheduling — a daily root-zone water balance that tracks inputs (rain, irrigation) against outputs (evapotranspiration) to estimate how much plant-available water remains in the soil. The core output is **AD (Allowable Depletion)**, a running daily tally in inches of water. When AD approaches zero the soil is at the irrigation trigger point.

The application is a Rails 8 web app backed by PostgreSQL. It pulls reference ET and precipitation from an external ag-weather microservice (REST API). All irrigation and soil moisture inputs come from growers entering data.

---

### Domain Model Hierarchy

```
User (Devise auth)
  └── Group (farm operation)
      └── Farm (one per year)
          └── Pivot (irrigation equipment / GPS location)
              └── Field (soil + crop configuration)
                  ├── Crop (plant type, emergence date, MAD, root zone)
                  └── FieldDailyWeather (one row per calendar day)
```

Fields can also share weather/irrigation data across multiple fields via **WeatherStation** (called "Field Groups" in the UI), linked through `multi_edit_links`.

---

### Static Configuration (set once per field/season)

| Parameter | Source | Description |
|-----------|--------|-------------|
| Soil type | User selects | Determines field capacity and wilting point |
| Field capacity (FC) | Soil type lookup or manual | Fraction of soil volume that holds water (e.g., 0.24 for loam) |
| Permanent wilting point (PWP) | Soil type lookup or manual | Fraction below which plants cannot extract water |
| Managed root zone depth (MRZD) | Crop default or manual | Depth in inches of active root zone |
| Max allowable depletion (MAD) | Crop default (50%) | Fraction of TAW that can deplete before irrigation is needed |
| Emergence date | User enters | Date crop emerged; governs canopy/LAI growth start |
| ET method | User selects | Percent Cover or LAI |

#### Soil Type Reference Table

| Soil | Field Capacity | Perm. Wilting Pt |
|------|---------------|-----------------|
| Sand | 0.10 | 0.04 |
| Sandy Loam | 0.15 | 0.05 |
| Loam | 0.24 | 0.08 |
| Silt Loam | 0.30 | 0.16 |
| Silt | 0.31 | 0.10 |
| Clay Loam | 0.34 | 0.15 |
| Clay | 0.37 | 0.20 |

#### Crop Default Root Zone Depths

| Crop | MRZD (inches) | Crop | MRZD (inches) |
|------|--------------|------|--------------|
| Onion | 12 | Sweet Corn | 27 |
| Carrot | 12 | Asparagus | 27 |
| Leafy Greens | 12 | Soybean | 33 |
| Cabbage | 15 | Field Corn | 33 |
| Broccoli | 15 | Wheat | 33 |
| Celery | 15 | Barley | 33 |
| Mint | 15 | Shell Peas | 36 |
| Tomato | 15 | Other | 36 |
| Potato | 16 | Alfalfa | 42 |
| Sweet Potato | 16 | Snap Bean | 21 |
| Beets | 18 | Pepper | 18 |
| Melon | 18 | Pumpkin | 18 |
| Cucumber | 18 | Winter Squash | 18 |
| Summer Squash | 18 | | |

---

### Derived Setup Values (calculated once, recalculated if soil/crop changes)

```
TAW  = (FC - PWP) × MRZD                          [inches; Total Available Water]
AD_max = MAD_frac × TAW                            [inches; max AD before irrigation needed]
pct_moisture_at_AD_min = (FC − (AD_max / MRZD)) × 100   [%; soil moisture at irrigation trigger]
```

These values define the "water budget" for the season. AD ranges from 0 (full, at field capacity) down to AD_max (at irrigation trigger) and further down to the permanent wilting point.

---

### Daily Calculation Loop

WISP runs April 1 – November 30. For each day the following inputs are needed:

| Input | Source in WISP | Notes |
|-------|---------------|-------|
| `ref_ET` | ag-weather microservice (inches/day) | ETo, reference evapotranspiration |
| `rain` | ag-weather microservice (inches) | Overrideable by grower |
| `irrigation` | Grower-entered (inches) | |
| `pct_cover` or `leaf_area_index` | User-entered / interpolated / growth curve | Depends on ET method |

#### Step 1 — Compute Adjusted ET

The reference ET (ETo) is a standardized value for a reference grass surface. A crop coefficient scales it for actual crop water use.

**Percent Cover Method** (default, most common):

Uses regression coefficients from UW Extension pub A3600 (Table C), derived by J. Panuska, that relate percent canopy cover to a crop coefficient. The lookup covers 0–80%+ cover in 10% bands. Below 80% cover, two adjacent band values are interpolated linearly. At or above 80% cover, `adj_ET = ref_ET` (full crop coefficient ≈ 1.0).

```
# Regression coefficients [intercept, slope] per 10% cover band:
coeff = [
  [0,0],           # 0%  — special case (see below)
  [-0.002263, 0.2377],  # 10%
  [-0.002789, 0.3956],  # 20%
  [-0.002368, 0.5395],  # 30%
  [-0.000316, 0.6684],  # 40%
  [-0.000053, 0.7781],  # 50%
  [ 0.001053, 0.8772],  # 60%
  [ 0.001947, 0.9395],  # 70%
  [ 0.000000, 1.0000],  # 80%+
]

# For a given pct_cover and ref_ET:
band = floor(pct_cover / 10)
adj_ET_low  = coeff[band][0]   + ref_ET * coeff[band][1]
adj_ET_high = coeff[band+1][0] + ref_ET * coeff[band+1][1]
adj_ET = adj_ET_low + ((pct_cover - band*10) / 10) * (adj_ET_high - adj_ET_low)
```

*Special case at 0% cover:* a stepped lookup by ref_ET magnitude handles the bare-soil ET (0.0 / 0.010 / 0.020 inches/day for low/medium/high ref_ET), then interpolates up to the 10% band value.

**LAI Method** (alternate, currently corn-specific in WISP):

```
# Corn LAI growth curve (days since emergence):
LAI = 9e-12 × days_since_emergence^7.95 × exp(-0.1 × days_since_emergence)

# Crop coefficient and adjusted ET:
Kc = 1.1 × (1 − exp(−1.5 × LAI))
adj_ET = Kc × ref_ET
```

For non-corn crops in the LAI path, WISP currently uses a degree-day based placeholder quadratic: `LAI ≈ −0.000003 × DD² + 0.0073 × DD − 0.6728`.

#### Step 2 — Compute Change in Daily Storage

```
delta_storage = rain + irrigation − adj_ET
```

#### Step 3 — Update AD

```
water_inches = prev_AD + delta_storage

if water_inches > AD_max:
    AD = AD_max
    deep_drainage = water_inches − AD_max    # excess drains below root zone
else:
    AD = water_inches
    deep_drainage = 0.0

# Hard floor at permanent wilting point:
AD = max(AD, −(1 − MAD_frac) × TAW)        # AD_at_PWP
```

Deep drainage is logged but otherwise discarded — it is water that has percolated below the root zone.

#### Step 4 — Compute Soil Moisture Percent

```
pct_moisture = pct_moisture_at_AD_min + (AD / MRZD) × 100
```

This back-converts AD (inches of available water) to a volumetric soil moisture percentage for display and for comparison against sensor readings.

#### Missing ET Handling

When `ref_ET` is zero or missing for a day, WISP substitutes the **mean of the top 3 adjusted ET values from the prior 7 days** (via a rolling ring buffer). This prevents the water balance from freezing on data-gap days.

#### Soil Moisture Override (Observation Reset)

If the user enters an **observed soil moisture %** for a day, the normal rain/ET/irrigation delta is bypassed. Instead, AD is re-derived directly from the observation:

```
AD = MRZD × (obs_pct_moisture − pct_moisture_at_AD_min) / 100
AD = min(AD, TAW)    # cannot exceed field capacity
```

This is a critical feature for resetting the modeled balance after a sensor reading or soil probe measurement.

---

### Percent Cover Interpolation

Between user-entered canopy cover dates, WISP linearly interpolates the `calculated_pct_cover` column. The user enters a few anchor points (e.g., emergence = 0%, 4 weeks later = 40%, at peak = 80%) and the system fills in daily values. This is the primary way canopy data is managed in practice.

---

### ET Method Summary Comparison

| | Percent Cover | LAI |
|-|--------------|-----|
| **User input** | % canopy cover on key dates | — (automatic growth curve) |
| **Growth curve** | None (user provides) | Polynomial/exponential function of days since emergence |
| **Crop coeff** | Regression table (A3600) | Beer's law: 1.1×(1−e^(−1.5×LAI)) |
| **Best for** | Any crop, simple, widely used | Corn (calibrated), requires degree-day data |
| **Mesonet fit** | Excellent | Possible if degree-days available |

---

### External Weather Dependency

WISP calls an ag-weather REST microservice (running on port 8080) to fetch:

- `/evapotranspirations` — reference ET by lat/lon and date range
- `/precips` — precipitation by lat/lon and date range
- `/degree_days` — accumulated degree days (for LAI crops)

The mesonet replaces this dependency entirely for the simplified implementation.

---

### Irrigation Trigger Logic

The daily status column color-codes fields:
- **Blue** — AD > 0 (water in the bank, no irrigation needed)
- **Yellow** — AD is within 2 days of 0 at projected ET rates
- **Red** — AD ≤ 0 (irrigation overdue)

Projection uses the rolling mean of recent adj_ET values (same ring-buffer calculation as the missing ET fill).

---

## Part 2: Mesonet Implementation Plan

### Objective

Add an irrigation scheduling widget to the state mesonet website that computes the daily water balance for a user-selected weather station, without a persistent database. The user provides a small number of inputs; the mesonet provides weather data. The calculation runs entirely in the browser (or on a stateless API call) for the current season to date.

---

### Key Simplifications vs. WISP

| WISP feature | Mesonet approach |
|-------------|-----------------|
| Multi-user accounts, farms, pivots, fields | No accounts; single-session, stateless |
| Persistent daily weather records | Fetch live from mesonet on demand |
| Full irrigation event tracking | User can optionally enter irrigation amounts |
| Observed soil moisture reset per day | User enters current soil moisture once to reset |
| Linear interpolation of pct_cover over season | User enters a single current pct_cover value |
| Multiple crops per field across years | One crop type per session |

---

### User Inputs

#### Required (always shown)

| Input | Options | Maps to |
|-------|---------|---------|
| Weather station | Dropdown of mesonet stations | Data source for ref_ET, precip |
| Crop type | Dropdown (crop list from plants.yml) | Default MRZD, MAD |
| Soil type | Dropdown (7 soil types) | FC, PWP |
| Current % canopy cover | 0–100% slider or text field | adj_ET calculation |
| Season start / emergence date | Date picker (defaults to May 1) | Start of water balance |

#### Optional / Adjustable (collapsible "Advanced" section)

| Input | Default | Notes |
|-------|---------|-------|
| Current soil moisture (%) | Computed from balance | Allows observation-based reset |
| Root zone depth (inches) | Crop default | Override if known |
| MAD fraction | 0.50 | Override for sensitive crops |
| Irrigation applied (inches, per date) | 0 | Key override for accuracy |
| Precipitation adjustments | Mesonet value | User can correct for local gauge |

---

### Mesonet Data Used

The mesonet already provides these per-station, per-day values:

| Data | WISP equivalent | Notes |
|------|----------------|-------|
| Reference ET (ETo, inches/day) | `ref_et` | Must be in inches; convert from mm if needed |
| Precipitation (inches) | `rain` | User-adjustable |
| Soil moisture (%) | `entered_pct_moisture` | Optional reset/anchor |
| Temperature (°F) | Degree days (optional) | Only needed for LAI method |

---

### Recommended ET Method for Mesonet

**Use the Percent Cover method.** It requires only a single canopy cover value entered by the user, uses no degree-day data, and is the most widely applicable across crop types. The LAI method could be offered as an advanced option for corn growers if degree-day data is available.

---

### Calculation Flow (stateless, single session)

```
1. User selects station, crop, soil type, pct_cover, emergence date
2. Fetch daily weather (ref_ET, precip) from mesonet API for
   emergence_date → today
3. Apply static setup:
     FC, PWP   ← soil type table
     MRZD      ← crop table (or user override)
     MAD_frac  ← 0.5 (or user override)
     TAW       = (FC − PWP) × MRZD
     AD_max    = MAD_frac × TAW
     pct_at_min = (FC − AD_max/MRZD) × 100
4. Set initial AD:
     If user entered current soil moisture → convert to AD
     Else → AD = 0.0  (assume field at capacity at season start)
5. For each day from emergence_date to today:
     adj_ET = adj_et_pct_cover(ref_ET, pct_cover)
     delta  = rain + irrigation − adj_ET
     AD, DD = daily_ad_and_dd(prev_AD, delta, MAD_frac, TAW)
     AD     = max(AD, AD_at_PWP)
     pct_moisture = pct_at_min + (AD / MRZD × 100)
     If user has entered obs. moisture for this date:
       Override AD and pct_moisture from observation
6. Display daily table + current status
7. Optionally project 3–5 days forward using recent avg adj_ET
```

**Canopy cover handling:** For simplicity, use the single user-entered % cover as a constant for the entire season to date. Alternatively, offer a simple two-point input: emergence date (0%) and "today" (user's value), then linearly interpolate.

---

### Output Display

| Column | Description |
|--------|-------------|
| Date | Calendar date |
| Ref. ET (in) | From mesonet |
| Adj. ET (in) | After crop coefficient |
| Rain (in) | From mesonet (E = user-edited) |
| Irrigation (in) | User-entered |
| AD (in) | Running water balance |
| Soil Moisture (%) | Computed (E = entered by user) |
| Status | Full / OK / Caution / Irrigate |

**Status thresholds (relative to AD_max):**

| Status | Condition |
|--------|-----------|
| Full | AD > AD_max × 0.9 |
| OK | AD > AD_max × 0.5 |
| Caution | AD > 0 |
| Irrigate | AD ≤ 0 |

---

### Implementation Technology Options

| Approach | Pros | Cons |
|----------|------|------|
| Pure JavaScript / HTML in browser | Zero backend, instant, embeds in existing site | Weather API must allow CORS |
| Thin server-side script (Python/PHP) | Handles CORS, easy to add state if needed later | Requires server endpoint |
| Progressive web app / React component | Best for interactive editing, responsive | More build infrastructure |

The calculation logic is simple enough to implement cleanly in JavaScript (no framework required) or as a single Python/Ruby script. The math is ~50 lines of pure functions with no dependencies.

---

### Pseudocode Reference (language-agnostic)

```python
# SETUP
FC, PWP = soil_type_lookup[soil_type]
MRZD = crop_lookup[crop_type]["mrzd"]
MAD = 0.50
TAW = (FC - PWP) * MRZD
AD_max = MAD * TAW
pct_at_min = (FC - AD_max / MRZD) * 100

# DAILY LOOP
def adj_et_pct_cover(ref_et, pct_cover):
    coeff = [(0,0),(-0.002263,0.2377),(-0.002789,0.3956),
             (-0.002368,0.5395),(-0.000316,0.6684),
             (-0.000053,0.7781),(0.001053,0.8772),
             (0.001947,0.9395),(0.0,1.0)]
    if ref_et < 1e-6: return 0.0
    band = min(int(pct_cover / 10), 7)
    if band >= 8: return ref_et
    lo = coeff[band][0]   + ref_et * coeff[band][1]
    hi = coeff[band+1][0] + ref_et * coeff[band+1][1]
    frac = (pct_cover - band * 10) / 10
    return lo + frac * (hi - lo)

def run_balance(days, initial_ad=0.0):
    ad = initial_ad
    results = []
    for day in days:
        if day.obs_moisture is not None:
            # Reset from observation
            ad = MRZD * (day.obs_moisture - pct_at_min) / 100
            ad = min(ad, TAW)
        else:
            adj_et = adj_et_pct_cover(day.ref_et, pct_cover)
            delta  = day.rain + day.irrigation - adj_et
            ad     = min(ad + delta, AD_max)
            ad     = max(ad, -(1 - MAD) * TAW)   # PWP floor
        pct_moist = pct_at_min + (ad / MRZD * 100)
        results.append({"date": day.date, "ad": ad, "pct_moisture": pct_moist})
    return results
```

---

### Phased Implementation Roadmap

#### Phase 1 — Core Calculator (MVP)
- Single-page tool: station dropdown, crop, soil, pct_cover, emergence date
- Fetch mesonet ref_ET and precip for current season
- Display daily water balance table with status indicator
- Highlight today's row; show "Irrigate now" / "OK" at top

#### Phase 2 — User Adjustments
- Editable precipitation column (flag adjusted values with "E")
- Irrigation input field per day (or a bulk "applied X inches on date Y" form)
- Soil moisture observation entry to reset the balance

#### Phase 3 — Enhanced Canopy Model
- Two-point canopy entry (emergence % and current %)
- Linear interpolation between points
- Optional: 3-day forward projection using recent avg ET

#### Phase 4 — Optional Persistence (if desired later)
- LocalStorage to remember station/crop/soil preferences
- URL-shareable state (encode inputs in query string)
- If server-side: lightweight session or signed token — no database required

---

### Key Equations Summary

| Calculation | Formula | Units |
|-------------|---------|-------|
| TAW | (FC − PWP) × MRZD | inches |
| AD_max | MAD × TAW | inches |
| pct_at_AD_min | (FC − AD_max/MRZD) × 100 | % |
| Adj. ET (pct cover) | Regression interpolation (A3600 table) | inches/day |
| Adj. ET (LAI corn) | 1.1 × (1 − e^(−1.5 × LAI)) × ref_ET | inches/day |
| Delta storage | rain + irrigation − adj_ET | inches/day |
| New AD | min(prev_AD + delta, AD_max) | inches |
| Deep drainage | max(0, prev_AD + delta − AD_max) | inches |
| Soil moisture | pct_at_AD_min + (AD/MRZD × 100) | % |

---

### Source References

- Core calculation gem: `vendor/asigbiophys/lib/` (ADCalculator, ETCalculator modules)
- Crop coefficients: UW Extension pub A3600, Table C (percent cover regression by J. Panuska)
- LAI corn curve: WI_Irrigation_Scheduler_(WIS)_VV6.3.11.xls
- Root zone depths: USDA NRCS Table 3.4 (nrcs141p2_017640.pdf)
- Soil water holding capacity: WISP `db/soil_types.yml`
- Plant defaults: WISP `db/plants.yml`
