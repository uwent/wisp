require 'test_helper'

class FieldDailyWeatherTest < ActiveSupport::TestCase
  WILT = 0.2
  ET = 0.2
  INITIAL_AD = 0.5
  def setup
    @field = Field.create(:perm_wilting_pt => WILT,:pivot_id => Pivot.first[:id])
    @field.crops << crops(:default)
  end
  test "fixtures are set up to do something useful" do
    assert(@field, "Should be a field")
    first_crop = @field.crops.first
    assert(first_crop,"Field should have a crop")
    assert(first_crop.emergence_date, "Crop should have an emergence date")
    assert(first_crop.max_root_zone_depth, "Crop should have a max root zone depth")
    assert(first_crop.max_allowable_depletion_frac, "Crop should have a fractional max allowable depletion")
  end
  
  def create_field_with_crop
    crop = Crop.new(
      :emergence_date => Date.civil(2011,05,01),
      :max_root_zone_depth => 20,
      :max_allowable_depletion_frac => 0.5,
      :initial_soil_moisture => 0.5)
    field = Field.new(:perm_wilting_pt => WILT)
    field.crops << crop
    field.create_field_daily_weather
    field.save!
    field
  end
  
  test "update_balances can be called" do
    field = create_field_with_crop
    assert(field.field_daily_weather.first, "Field should have had daily weather")
  end
  
  test "update_balances does something useful" do
    field = create_field_with_crop
    fdw_first = field.field_daily_weather.first
    assert(fdw_first.field, "Field daily weather should have a field! #{fdw_first.inspect}")
    fdw_first.ad = INITIAL_AD
    fdw_first.save!
    puts "\nsaved the first day, it's now #{fdw_first.inspect}"
    fdw_second = field.field_daily_weather[1]
    assert(fdw_second.field, "Field daily weather should have a field! #{fdw_second.inspect}")
    assert_nil(fdw_second.ad)
    fdw_second.ref_et = ET
    puts "\nabout to save the second day's weather (#{fdw_second.inspect})"; $stdout.flush
    fdw_second.save!
    assert(fdw_second.ad, "Should have updated the second fdw to have an ad balance")
  end
  
  test "update_balances does something correct" do
    field = create_field_with_crop
    fdw_first = field.field_daily_weather.first
    fdw_first.ad = INITIAL_AD
    fdw_first.save!
    fdw_second = field.field_daily_weather[1]
    assert_nil(fdw_second.ad)
    fdw_second.ref_et = ET
    fdw_second.save!
    assert(fdw_second.ad, "Should have updated the second fdw to have an ad balance")
    assert_equal(INITIAL_AD - ET, fdw_second.ad,"AD should be the starting value minus ET")
  end
  
end
