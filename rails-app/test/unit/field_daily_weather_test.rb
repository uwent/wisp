require 'test_helper'

class FieldDailyWeatherTest < ActiveSupport::TestCase
  WILT = 0.2
  ET = 0.2
  INITIAL_AD = 0.5

  def setup
    @field = create_field_with_crop
  end

  def create_field_with_crop
    field = Field.create(
      :name => 'test field', :perm_wilting_pt => WILT, :field_capacity => 0.5,
      :pivot => pivots(:one) # rick's farm, which has LAI ET method
    )
    field.crops.first.update_attributes({
      :name => 'test crop',
      :emergence_date => Date.civil(2011,05,01),
      :max_root_zone_depth => 20,
      :max_allowable_depletion_frac => 0.5,
      :initial_soil_moisture => 0.5
      })
     field.save!
     field
  end
  
  # test "update_balances can be called" do
  #   field = create_field_with_crop
  #   assert(field.field_daily_weather.first, "Field should have had daily weather")
  # end
  # 
  test "update_balances does something useful" do
    fdw_first = @field.field_daily_weather[50]
    # puts "************************************************************************"; $stdout.flush
    # puts "************************************************************************"; $stdout.flush
    # puts "************************************************************************"; $stdout.flush
    # puts "FDW's field looks like #{@field.inspect}"; $stdout.flush
    # puts "and its first crop looks like #{@field.current_crop.inspect}"; $stdout.flush
    assert(fdw_first.field, "Field daily weather should have a field! #{fdw_first.inspect}")
    fdw_first.ad = INITIAL_AD
    fdw_first.ref_et = ET - 0.01
    fdw_first.save!                        
    # puts "\nsaved the first day, it's now #{fdw_first.inspect}"; $stdout.flush
    fdw_second = fdw_first.succ
    assert(fdw_second.field, "Field daily weather should have a field! #{fdw_second.inspect}")
    assert_nil(fdw_second.ad)
    fdw_second.ref_et = ET
    # puts "\nabout to save the second day's weather (#{fdw_second.inspect})"; $stdout.flush
    fdw_second.save!
    assert(fdw_second.ad, "Should have updated the second fdw to have an ad balance, but it's #{fdw_second.inspect}")
  end
  
  test "newly-created fdw should have zero rain and irrig" do
    fdw = FieldDailyWeather.create(:date => '2011-05-01')
    assert_equal(0.0, fdw.rain)
    assert_equal(0.0, fdw.irrigation)
  end
  
  test "update_balances does something correct" do
    field = create_field_with_crop
    fdw_first = field.field_daily_weather[50]
    fdw_first.ad = INITIAL_AD
    fdw_first.save!
    fdw_second = fdw_first.succ
    assert_nil(fdw_second.ad)
    fdw_second.ref_et = ET
    fdw_second.save!
    assert(fdw_second.ad, "Should have updated the second fdw to have an ad balance")
    assert_in_delta(0.28996375716993095, fdw_second.ad, 2 ** -20)
  end
  
  test "previous and next work" do
    fdw_first = FieldDailyWeather.first
    fdw_second = FieldDailyWeather.where(:field_id => fdw_first[:field_id])[1]
    assert_equal([], FieldDailyWeather.previous(fdw_first),"First FDW, should have no pred")
    assert_equal([fdw_second], FieldDailyWeather.next(fdw_first),"Second FDW should have first one as pred")
    assert_equal([fdw_first], FieldDailyWeather.previous(fdw_second),"First FDW should have second one as succ")
  end
  
  test "pred and succ work" do
    fdw_first = FieldDailyWeather.first
    fdw_second = FieldDailyWeather.where(:field_id => fdw_first[:field_id])[1]
    assert_nil(fdw_first.pred,"First FDW, should have no pred")
    assert_equal(fdw_second, fdw_first.succ,"Second FDW should have first one as pred")
    assert_equal(fdw_first, fdw_second.pred,"First FDW should have second one as succ")
  end 
  
  
end
