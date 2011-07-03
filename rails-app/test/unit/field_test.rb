require 'test_helper'

class FieldTest < ActiveSupport::TestCase
  
  def setup
    @pcf = fields(:one)
  end
  
  test "et_method method works" do
    method = nil
    assert_nothing_raised(Exception) { method = fields(:one).et_method }
    assert(method, "Should have returned an EtMethod")
    assert_equal(LaiEtMethod, method.class,"Should have returned an LAI EtMethod object")
  end

  test "fields can enumerate their weather" do
    default_field = fields(:default)
    assert(default_field.field_daily_weather, "This field should have weather")
    assert(default_field.field_daily_weather.size > 0, "Should have a few days of daily weather")
  end
  
  test "call all the methods from the AD Calculator" do
    assert_nothing_raised(Exception) { @pcf.calc_ad_max_inches(0.1,0.5) }
    assert_nothing_raised(Exception) { @pcf.calc_ad_max_inches(0.1,0.5) }
    fc = pwp = mrzd = mad_frac = taw = ad_max = daily_rain = daily_irrig = adj_et = prev_daily_ad = delta_stor = 0.5
    pct_moisture_at_ad_min = ad = pct_moisture_obs = mad_frac = 0.5
    assert_nothing_raised(Exception) {  @pcf.calc_taw(fc, pwp, mrzd) }
    assert_nothing_raised(Exception) {  @pcf.calc_ad_max_inches(mad_frac, taw) }
    assert_nothing_raised(Exception) {  @pcf.calc_pct_moisture_at_ad_min(fc, ad_max, mrzd) }
    assert_nothing_raised(Exception) {  @pcf.calc_change_in_daily_storage(daily_rain, daily_irrig, adj_et) }
    assert_nothing_raised(Exception) {  @pcf.calc_daily_ad(prev_daily_ad, delta_stor,mad_frac,taw) }
    assert_nothing_raised(Exception) {  @pcf.calc_pct_moisture_from_ad(pwp, fc, ad_max, ad, mrzd, pct_moisture_obs) }
    assert_nothing_raised(Exception) {  @pcf.calc_daily_deep_drainage_volume(ad_max, prev_daily_ad, delta_stor) }
    assert_nothing_raised(Exception) {  @pcf.calc_daily_ad_from_moisture(mad_frac,taw,mrzd,pct_moisture_at_ad_min,pct_moisture_obs) }
  end
  
  test "change_in_daily_storage works" do
    assert_equal(0.0, @pcf.calc_change_in_daily_storage(0.0,0.0,0.0))
    assert_equal(-0.2, @pcf.calc_change_in_daily_storage(0.0,0.0,0.2))
    assert_equal(0.2, @pcf.calc_change_in_daily_storage(0.0,0.2,0.0))
    assert_equal(0.2, @pcf.calc_change_in_daily_storage(0.2,0.0,0.0))
    assert_equal(0.4, @pcf.calc_change_in_daily_storage(0.2,0.2,0.0))
    assert_equal(0.0, @pcf.calc_change_in_daily_storage(0.2,0.2,0.4))
  end
  
  test "daily AD works below ad_max" do
    mad_frac = 0.5
    taw = 6.0
    prev_daily_ad = 2.0
    assert_equal(1.5, @pcf.calc_daily_ad(prev_daily_ad,-0.5,mad_frac,taw))
  end
  
  test "daily AD works above ad_max" do
    mad_frac = 0.5
    taw = 6.0
    prev_daily_ad = 10.0
    ad_max = @pcf.calc_ad_max_inches(mad_frac,taw)
    assert_equal(3.0, ad_max)
    assert_equal(ad_max, @pcf.calc_daily_ad(prev_daily_ad,20.0,mad_frac,taw))
  end
  
  test "let's do a one-day calc" do
    fdw = [FieldDailyWeather.create(
            :field => @pcf,
            :date => '2011-06-01',
            :ref_et => 0.32,
            :entered_pct_moisture => 0.5,
            :entered_pct_cover => 0.4)
          ]
  end
  
  test "start and end dates work" do
    field = fields(:default)
    assert(field)
    year = field.year
    assert(year)
    start_date,end_date = field.date_endpoints
  end
  
  test "can create a season's worth of field daily weather" do
    field = Field.create(:pivot_id => Farm.first.pivots.first[:id])
    FieldDailyWeather.destroy_all
    field = Field.find(field[:id])
    start_date,end_date = field.date_endpoints
    n_days = 1 + (end_date - start_date)
    assert(field)
    assert_equal(0, field.field_daily_weather.size)
    field.create_field_daily_weather
    assert_equal(n_days, field.field_daily_weather.size)
  end
  
  test "ensure that field_daily_weather recs are created after field is created" do
    field = Field.create(:pivot_id => Farm.first.pivots.first[:id])
    start_date,end_date = field.date_endpoints
    n_days = 1 + (end_date - start_date)
    assert_equal(n_days, field.field_daily_weather.size)
  end
  
  test "field_daily_weather for a field all gets deleted when the field goes away" do
    field = Field.create(:pivot_id => Farm.first.pivots.first[:id])
    fdw = FieldDailyWeather.where(:field_id => field[:id])
    start_date,end_date = field.date_endpoints
    n_days = 1 + (end_date - start_date)
    assert_equal(n_days, fdw.size)
    field.destroy
    fdw = FieldDailyWeather.where(:field_id => field[:id])
    assert_equal(0, fdw.size, "All the weather records should have shuffled off.")
  end

  def check_lai_profile(field,emergence_date)
    lai = nil
    field.field_daily_weather.each do |fdw|
      if fdw.date < emergence_date
        assert_nil(fdw.leaf_area_index)
      elsif fdw.date == emergence_date
        lai = fdw.leaf_area_index
        assert(lai, "Should be an LAI value starting at emergence date")
      elsif fdw.date > emergence_date + 61
        break
      else
        assert(fdw.leaf_area_index > lai, "LAI should be increasing for the first two months. For #{fdw.date}, LAI was #{fdw.leaf_area_index} and previous day's was #{lai}")
        lai = fdw.leaf_area_index
      end
    end
  end

  def check_field_has_no_lai(field,emergence_date)
    fdw_emergence_date = (field.field_daily_weather.find_all {|fdw| fdw.date == emergence_date}).first
    assert(fdw_emergence_date, "Should be a wx record for emergence date")
    assert_nil(fdw_emergence_date.leaf_area_index,"Should start out with nothing for LAI on emergence date")
  end

  def setup_field_with_emergence
    farm = Farm.first
    assert_equal(LaiEtMethod, farm.et_method.class)
    field = Field.create(:pivot_id => farm.pivots.first[:id])
    emergence_date = DateTime.parse('2011-05-01')
    check_field_has_no_lai(field,emergence_date)
    [field,emergence_date]
  end
  
  test "update_canopy called directly works for lai" do
    field,emergence_date = setup_field_with_emergence
    field.update_canopy(emergence_date)
    check_lai_profile(field,emergence_date)
  end
  
  test "setting crop emergence date works for lai" do
    FieldDailyWeather.destroy_all
    assert_equal(0, FieldDailyWeather.count)
    field,emergence_date = setup_field_with_emergence
    field_id = field[:id]
    field.crops << (crop = Crop.new)
    check_field_has_no_lai(field,emergence_date)
    crop.emergence_date = emergence_date
    crop.save!
    field = Field.find(field_id)
    check_lai_profile(field,emergence_date)
  end
  
  test "I can get the correct index for a date" do
    field,emergence_date = setup_field_with_emergence
    fdw_start = field.field_daily_weather.first
    start_date = DateTime.parse(fdw_start.date.to_s)
    assert_equal(0, field.fdw_index(start_date))
    assert_equal(emergence_date - start_date, field.fdw_index(emergence_date))
  end
  
end
