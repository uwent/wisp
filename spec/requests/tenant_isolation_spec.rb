require "rails_helper"

# Every record lookup driven by request params (or by IDs stashed in the session from params)
# must be scoped to the signed-in user's group. These specs sign in as one user and attempt to
# read or modify another user's records by ID.
describe "Tenant isolation", type: :request do
  let!(:attacker) { create(:user, email: "attacker@example.com") }
  let!(:victim) { create(:user, email: "victim@example.com") }

  let(:victim_group) { victim.groups.first }
  let(:victim_farm) { victim_group.farms.first }
  let(:victim_pivot) { victim_farm.pivots.first }
  let(:victim_field) { victim_pivot.fields.first }
  let(:victim_crop) { victim_field.crops.first }
  let(:victim_fdw) { victim_field.field_daily_weather.first }

  let(:attacker_group) { attacker.groups.first }
  let(:attacker_farm) { attacker_group.farms.first }
  let(:attacker_pivot) { attacker_farm.pivots.first }
  let(:attacker_field) { attacker_pivot.fields.first }

  # jqGrid posts every column of the edited row, so mirror that here
  def field_row(field, overrides = {})
    {
      id: field.id, parent_id: field.pivot_id, pivot_id: field.pivot_id, name: field.name,
      et_method: field.et_method, area: field.area, soil_type_id: field.soil_type_id,
      field_capacity_pct: field.field_capacity_pct, perm_wilting_pt_pct: field.perm_wilting_pt_pct,
      target_ad_pct: field.target_ad_pct, notes: field.notes
    }.merge(overrides)
  end

  def crop_row(crop, overrides = {})
    {
      id: crop.id, parent_id: crop.field_id, name: crop.name, plant_id: crop.plant_id,
      variety: crop.variety, emergence_date: crop.emergence_date, harvest_or_kill_date: crop.harvest_or_kill_date,
      max_root_zone_depth: crop.max_root_zone_depth,
      max_allowable_depletion_frac: crop.max_allowable_depletion_frac, notes: crop.notes
    }.merge(overrides)
  end

  before do
    victim_farm.update!(name: "VICTIM-FARM")
    victim_pivot.update!(name: "VICTIM-PIVOT")
    victim_field.update!(name: "VICTIM-FIELD")
    victim_fdw.update_columns(notes: "VICTIM-NOTES")
    post user_session_path, params: {user: {email: attacker.email, password: "password"}}
  end

  describe "field daily weather" do
    it "cannot edit another group's daily record" do
      post post_data_field_daily_weather_index_path, params: {id: victim_fdw.id, irrigation: "5.0"}
      expect(victim_fdw.reload.irrigation).to eq(0.0)
    end

    it "cannot list another group's daily records" do
      get field_daily_weather_index_path(format: :json), params: {field_id: victim_field.id}
      expect(response.body).not_to include("VICTIM-NOTES")
    end

    it "can still edit its own daily record" do
      fdw = attacker_field.field_daily_weather.first
      post post_data_field_daily_weather_index_path, params: {id: fdw.id, irrigation: "1.5"}
      expect(fdw.reload.irrigation).to eq(1.5)
    end
  end

  describe "fields" do
    it "cannot rename another group's field" do
      post post_data_fields_path, params: field_row(victim_field, name: "pwned")
      expect(victim_field.reload.name).to eq("VICTIM-FIELD")
    end

    it "cannot delete another group's field" do
      post post_data_fields_path, params: {oper: "del", id: victim_field.id, parent_id: victim_pivot.id}
      expect(Field.exists?(victim_field.id)).to be(true)
    end

    it "cannot add a field to another group's pivot" do
      expect {
        post post_data_fields_path, params: {oper: "add", pivot_id: victim_pivot.id, name: "intruder"}
      }.not_to change { victim_pivot.fields.count }
    end

    it "cannot list another group's fields" do
      get fields_path(format: :json), params: {parent_id: victim_pivot.id}
      expect(response.body).not_to include("VICTIM-FIELD")
    end

    it "can still rename its own field" do
      post post_data_fields_path, params: field_row(attacker_field, name: "Mine")
      expect(attacker_field.reload.name).to eq("Mine")
    end
  end

  describe "pivots" do
    it "cannot rename another group's pivot" do
      post post_data_pivots_path, params: {id: victim_pivot.id, parent_id: victim_farm.id, name: "pwned"}
      expect(victim_pivot.reload.name).to eq("VICTIM-PIVOT")
    end

    it "cannot delete another group's pivot" do
      victim_farm.pivots.create!(name: "second")
      post post_data_pivots_path, params: {oper: "del", id: victim_pivot.id, parent_id: victim_farm.id}
      expect(Pivot.exists?(victim_pivot.id)).to be(true)
    end

    it "cannot add a pivot to another group's farm" do
      expect {
        post post_data_pivots_path, params: {oper: "add", parent_id: victim_farm.id, name: "intruder"}
      }.not_to change { victim_farm.pivots.count }
    end

    it "cannot read another group's pivot" do
      get pivots_path(format: :json), params: {pivot_id: victim_pivot.id, page: 1, rows: 10}
      expect(response.body).not_to include("VICTIM-PIVOT")
    end

    it "can still rename its own pivot" do
      post post_data_pivots_path, params: {id: attacker_pivot.id, parent_id: attacker_farm.id, name: "Mine"}
      expect(attacker_pivot.reload.name).to eq("Mine")
    end
  end

  describe "farms" do
    it "cannot rename another group's farm" do
      post post_data_farms_path, params: {id: victim_farm.id, name: "pwned"}
      expect(victim_farm.reload.name).to eq("VICTIM-FARM")
    end

    it "cannot read another group's farm problems" do
      get problems_farms_path, params: {farm_id: victim_farm.id}
      expect(response).to have_http_status(:not_found)
    end

    it "can still rename its own farm" do
      post post_data_farms_path, params: {id: attacker_farm.id, name: "Mine"}
      expect(attacker_farm.reload.name).to eq("Mine")
    end
  end

  describe "crops" do
    it "cannot edit another group's crop" do
      post post_data_crops_path, params: crop_row(victim_crop, variety: "pwned")
      expect(victim_crop.reload.variety).not_to eq("pwned")
    end

    it "cannot delete another group's crop" do
      post post_data_crops_path, params: {oper: "del", id: victim_crop.id, parent_id: victim_field.id}
      expect(Crop.exists?(victim_crop.id)).to be(true)
    end

    it "can still edit its own crop" do
      crop = attacker_field.crops.first
      post post_data_crops_path, params: crop_row(crop, variety: "Russet")
      expect(crop.reload.variety).to eq("Russet")
    end
  end

  describe "wisp pages" do
    it "cannot fetch another group's projection data" do
      get projection_data_wisp_index_path(format: :json), params: {field_id: victim_field.id}
      expect(response).to have_http_status(:not_found)
    end

    it "cannot fetch another group's summary box" do
      get summary_box_wisp_index_path, params: {field_id: victim_field.id}
      expect(response).to have_http_status(:not_found)
    end

    it "cannot select another group's field into the session" do
      post set_field_wisp_index_path, params: {field_id: victim_field.id}
      expect(response).to have_http_status(:not_found)
      expect(session[:field_id]).not_to eq(victim_field.id.to_s)
    end

    it "cannot select another group's farm into the session" do
      post set_farm_wisp_index_path, params: {farm_id: victim_farm.id}
      expect(response).to have_http_status(:not_found)
      expect(session[:farm_id]).not_to eq(victim_farm.id.to_s)
    end

    it "cannot open another group's pivot" do
      get pivot_crop_wisp_index_path, params: {pivot_id: victim_pivot.id}
      expect(response).to have_http_status(:not_found)
    end

    it "falls back to its own field when given another group's field" do
      get field_status_wisp_index_path, params: {field_id: victim_field.id}
      expect(response.body).not_to include("VICTIM-FIELD")
    end
  end

  describe "field groups (weather stations)" do
    let!(:victim_station) do
      victim_group.weather_stations.create!(name: "VICTIM-STATION").tap { |ws| ws.fields << victim_field }
    end

    it "cannot link another group's field into a new field group" do
      post weather_stations_path, params: {weather_station: {name: "mine", field_ids: [victim_field.id]}}
      expect(victim_field.reload.weather_stations).to eq([victim_station])
    end

    it "cannot update another group's field group" do
      patch weather_station_path(victim_station), params: {weather_station: {name: "pwned", field_ids: []}}
      expect(victim_station.reload.name).to eq("VICTIM-STATION")
      expect(victim_station.fields).to eq([victim_field])
    end

    it "cannot edit another group's field group daily data" do
      victim_station.ensure_data_for(Date.current.year)
      wsd = victim_station.weather_station_data.first
      post post_data_weather_station_data_index_path, params: {id: wsd.id, irrigation: "5.0"}
      expect(wsd.reload.irrigation).to be_nil
    end

    it "can still create a field group with its own fields" do
      post weather_stations_path, params: {weather_station: {name: "mine", field_ids: [attacker_field.id]}}
      expect(attacker_group.weather_stations.find_by(name: "mine").fields).to eq([attacker_field])
    end
  end
end
