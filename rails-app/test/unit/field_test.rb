require 'test_helper'

class FieldTest < ActiveSupport::TestCase
  
  def setup
    @pcf = fields(:one)
  end
  
  test "et_method method works" do
    method = nil
    assert_nothing_raised(Exception) { method = fields(:one).et_method }
    assert(method, "Should have returned an EtMethod")
    assert_equal(PctCoverEtMethod, method.class,"Should have returned an EtMethod object")
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
  
end
