require 'test_helper'

class FieldDailyWeatherTest < ActiveSupport::TestCase
  def setup
    @field = Field.create(:perm_wilting_pt => 0.2,:pivot_id => Pivot.first[:id])
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
    crop = Crop.new(:emergence_date => DateTime.parse('2011-05-01'), :max_root_zone_depth => 20,:max_allowable_depletion_frac => 0.5 )
    field = Field.new(:perm_wilting_pt => 0.2)
    field.crops << crop
    field.create_field_daily_weather
    field
  end
  
  test "update_balances can be called" do
    field = create_field_with_crop
    assert(field.field_daily_weather.first, "Field should have had daily weather")
  end
  
  test "update_balances do something useful" do
    field = create_field_with_crop
    fdw_first = field.field_daily_weather.first
    fdw_first.ad = 0.5
    fdw_first.save!
    fdw_second = field.field_daily_weather[1]
    assert_nil(fdw_second.ad)
    fdw_second.ref_et = 0.2
    fdw_second.save!
    assert(fdw_second.ad, "Should have updated the second fdw to have an ad balance")
  end
  
end
