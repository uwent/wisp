# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_04_23_140901) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "blogs", force: :cascade do |t|
    t.date "date"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "crops", force: :cascade do |t|
    t.integer "field_id"
    t.string "name", limit: 255
    t.string "variety", limit: 255
    t.date "emergence_date"
    t.date "end_date"
    t.date "harvest_or_kill_date"
    t.float "max_root_zone_depth"
    t.float "max_allowable_depletion_frac"
    t.float "max_allowable_depletion_inches"
    t.string "notes", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "initial_soil_moisture"
    t.integer "plant_id"
  end

  create_table "farms", force: :cascade do |t|
    t.integer "group_id"
    t.integer "year"
    t.string "name", limit: 255
    t.string "notes", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "field_daily_weather", force: :cascade do |t|
    t.integer "field_id"
    t.date "date"
    t.float "ref_et"
    t.float "adj_et"
    t.float "rain"
    t.float "irrigation"
    t.float "entered_pct_moisture"
    t.float "entered_pct_cover"
    t.float "leaf_area_index"
    t.float "calculated_pct_moisture"
    t.float "ad"
    t.float "deep_drainage"
    t.string "notes", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "calculated_pct_cover"
    t.integer "degree_days"
  end

  create_table "fields", force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "soil_type_id"
    t.float "area"
    t.float "field_capacity"
    t.float "perm_wilting_pt"
    t.integer "pivot_id"
    t.integer "ref_et_station_id"
    t.integer "rain_station_id"
    t.integer "soil_moisture_station_id"
    t.string "notes", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "target_ad_pct"
    t.integer "et_method"
  end

  create_table "groups", force: :cascade do |t|
    t.string "description", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "irrigation_events", force: :cascade do |t|
    t.integer "pivot_id"
    t.date "date"
    t.float "inches_applied"
    t.float "run_time"
    t.float "total_volume"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "group_id"
    t.integer "user_id"
    t.boolean "is_admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "multi_edit_links", force: :cascade do |t|
    t.integer "field_id"
    t.integer "weather_station_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pivots", force: :cascade do |t|
    t.integer "farm_id"
    t.string "name", limit: 255
    t.float "latitude"
    t.float "longitude"
    t.string "equipment", limit: 255
    t.float "pump_capacity"
    t.string "some_energy_rate_metric"
    t.integer "cropping_year", null: false
    t.string "notes", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "plants", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "type", limit: 255
    t.float "default_max_root_zone_depth"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "soil_types", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "description", limit: 255
    t.float "field_capacity"
    t.float "perm_wilting_pt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_soil_types_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", limit: 255
    t.string "last_name", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.boolean "admin", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "idx_users_index_users_on_reset_password_token", unique: true
  end

  create_table "weather_station_data", force: :cascade do |t|
    t.integer "weather_station_id", null: false
    t.date "date", null: false
    t.float "ref_et"
    t.float "rain"
    t.float "entered_pct_moisture"
    t.string "notes", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "irrigation"
    t.float "entered_pct_cover"
    t.float "leaf_area_index"
    t.index ["weather_station_id", "date"], name: "index_weather_station_data_on_weather_station_id_and_date", unique: true
  end

  create_table "weather_stations", force: :cascade do |t|
    t.integer "group_id"
    t.string "name", limit: 255
    t.string "location", limit: 255
    t.string "notes", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "pivot_id_deleted"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
