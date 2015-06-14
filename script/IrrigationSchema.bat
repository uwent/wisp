echo "This script is obsolete! Look at schema.rb, which is definitive, and ensure that the migrations"
echo "agree with it."
exit 1
rails generate model User email:string openid_url:string
rails generate model Group description:string
rails generate model Membership group_id:integer user_id:integer
rails generate model Farm group_id:integer name:string et_method_id:integer notes:string
rails generate model Pivot farm_id:integer name:string latitude:float longitude:float equipment:string pump_capacity:float some_energy_rate_metric:float cropping_year:integer notes:string
rails generate model IrrigationEvent pivot_id:integer inches_applied:float run_time:float total_volume:float
rails generate model Field pivot_id:integer name:string soil_type:string area:float field_capacity:float perm_wilting_pt:float ref_et_station_id:integer rain_station_id:integer soil_moisture_station_id:integer notes:string
rails generate model Crop field_id:integer end_date:datetime crop:string variety:string emergence_date:datetime harvest_or_kill_date:datetime max_root_zone_depth:float max_allowable_depletion_frac:float max_allowable_depletion_inches:float notes:string
rails generate model FieldDailyWeather field_id:integer date:datetime ref_et:float adj_et:float rain:float irrigation:float entered_pct_moisture:float entered_pct_cover:float entered_leaf_area_index:float notes:string
rails generate model WeatherStation group_id:integer name:string location:string notes:string
rails generate model WeatherStationData station_id:integer date:datetime ref_et:float rainfall:float  soil_moisture:float notes:string