# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Wisconsin Irrigation Scheduling Program (WISP)** — a Rails 8.0 web app for irrigation water management, developed for UW-Madison. It tracks daily root-zone water balance (rainfall, irrigation, ET, deep drainage) using the checkbook method and integrates with an external ag-weather microservice.

## Commands

```bash
# Development
bin/rails s                          # Start server (localhost:3000)
bundle exec rspec                    # Run all tests
bundle exec rspec spec/path/to_spec.rb  # Run a single test file
bundle exec standard                 # Lint (Ruby Standard)

# Database
bundle exec rake db:setup db:seed    # Create DB, load schema, seed plants/soil types
bundle exec rake yearly:reset        # Reset all field data (runs automatically Feb 15)

# Deployment
cap staging deploy                   # Deploy to dev.wisp.cals.wisc.edu
cap production deploy                # Deploy to wisp.cals.wisc.edu
```

Guard can auto-run tests on file changes: `guard -i rspec`

## Architecture

### Domain Model Hierarchy

```
User (Devise auth)
  └── Group (farm operation group, via memberships)
      └── Farm (collection of pivots, one per year)
          └── Pivot (irrigation equipment / field location)
              └── Field (soil/crop area with water balance params)
                  ├── Crop (plant type + emergence date + MAD + root zone)
                  └── FieldDailyWeather (one row per day: rain, irrigation, ET, AD, soil moisture)
```

Fields also link to **WeatherStations** (called "Field Groups" in the UI) via `multi_edit_links`, allowing shared weather/irrigation data entry across grouped fields.

### Key Calculations (vendor gem: `asigbiophys`)

Located in `vendor/asigbiophys/lib/`:
- **`ADCalculator`** — Available water Depletion: tracks daily soil water balance
- **`ETCalculator`** — Evapotranspiration: uses reference ET from ag-weather + crop-specific coefficients, supporting two methods: Percent Cover or LAI (Leaf Area Index)

### External Dependency: ag-weather

`app/clients/ag_weather.rb` wraps REST calls to the ag-weather service running on port `8080`. This service provides reference ET, precipitation, and degree-day data. The app requires ag-weather to be running locally for full functionality.

### Plants (STI)

Plant types live in `app/models/plants/` as STI subclasses (Corn, Potato, Soybean, etc.) with definitions seeded from `db/plants.yml`. Soil water holding capacity defaults come from `db/soil_types.yml`.

### Routes & Controllers

All main WISP UI views route through `/wisp/*` (collection actions only — no standard CRUD). Resource controllers (`farms`, `pivots`, `fields`, `crops`, `field_daily_weather`, `weather_stations`) use jqGrid for server-side data tables and respond primarily to `index` + `post_data` actions.

### Security

- **Rack::Attack** (`config/initializers/rack_attack.rb`): rate-limits to 25 req/sec globally, 5 write req/sec per IP
- **Devise** handles authentication; group memberships (`memberships` table) control access with an admin flag

## Ruby & Rails Upgrades

When upgrading Ruby: update `.ruby-version`, `config/deploy.rb`, and the README version reference.

When upgrading Rails: `THOR_MERGE="code -d $1 $2" rails app:update` (uses VSCode as merge tool).

## Testing

RSpec with FactoryBot. Tests live in `spec/`. Migrations are excluded from Standard linting (`.standard.yml`).
