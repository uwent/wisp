# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20150627021927) do

  create_table "blogs", :force => true do |t|
    t.date     "date"
    t.text     "content"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "crops", :force => true do |t|
    t.integer  "field_id"
    t.string   "name"
    t.string   "variety"
    t.date     "emergence_date"
    t.date     "end_date"
    t.date     "harvest_or_kill_date"
    t.float    "max_root_zone_depth"
    t.float    "max_allowable_depletion_frac"
    t.float    "max_allowable_depletion_inches"
    t.string   "notes"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.float    "initial_soil_moisture"
    t.integer  "plant_id"
  end

  create_table "farms", :force => true do |t|
    t.integer  "group_id"
    t.integer  "year"
    t.string   "name"
    t.string   "notes"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "field_daily_weather", :force => true do |t|
    t.integer  "field_id"
    t.date     "date"
    t.float    "ref_et"
    t.float    "adj_et"
    t.float    "rain"
    t.float    "irrigation"
    t.float    "entered_pct_moisture"
    t.float    "entered_pct_cover"
    t.float    "leaf_area_index"
    t.float    "calculated_pct_moisture"
    t.float    "ad"
    t.float    "deep_drainage"
    t.string   "notes"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
    t.float    "calculated_pct_cover"
    t.integer  "degree_days"
  end

  create_table "fields", :force => true do |t|
    t.string   "name"
    t.integer  "soil_type_id"
    t.float    "area"
    t.float    "field_capacity"
    t.float    "perm_wilting_pt"
    t.integer  "pivot_id"
    t.integer  "ref_et_station_id"
    t.integer  "rain_station_id"
    t.integer  "soil_moisture_station_id"
    t.string   "notes"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.float    "target_ad_pct"
    t.integer  "et_method"
  end

  create_table "groups", :force => true do |t|
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "irrigation_events", :force => true do |t|
    t.integer  "pivot_id"
    t.date     "date"
    t.float    "inches_applied"
    t.float    "run_time"
    t.float    "total_volume"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "memberships", :force => true do |t|
    t.integer  "group_id"
    t.integer  "user_id"
    t.boolean  "is_admin"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "multi_edit_links", :force => true do |t|
    t.integer  "field_id"
    t.integer  "weather_station_id"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

  create_table "pivots", :force => true do |t|
    t.integer  "farm_id"
    t.string   "name"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "equipment"
    t.float    "pump_capacity"
    t.float    "some_energy_rate_metric"
    t.integer  "cropping_year"
    t.string   "notes"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  create_table "plants", :force => true do |t|
    t.string   "name"
    t.string   "type"
    t.float    "default_max_root_zone_depth"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
  end

  create_table "soil_types", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.float    "field_capacity"
    t.float    "perm_wilting_pt"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "soil_types", ["name"], :name => "index_soil_types_on_name", :unique => true

  create_table "users", :force => true do |t|
    t.string   "orig_email"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "identifier_url"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "provider"
    t.string   "uid"
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "weather_station_data", :force => true do |t|
    t.integer  "weather_station_id"
    t.date     "date"
    t.float    "ref_et"
    t.float    "rain"
    t.float    "entered_pct_moisture"
    t.string   "notes"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.float    "irrigation"
    t.float    "entered_pct_cover"
    t.float    "leaf_area_index"
  end

  create_table "weather_stations", :force => true do |t|
    t.integer  "group_id"
    t.string   "name"
    t.string   "location"
    t.string   "notes"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "pivot_id"
  end

end
