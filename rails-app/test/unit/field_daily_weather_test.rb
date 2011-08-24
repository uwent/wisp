require 'test_helper'

class FieldDailyWeatherTest < ActiveSupport::TestCase
  WILT = 0.14
  ET = 0.2
  INITIAL_AD = 0.31
  MID_AD = -0.47

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
    fdw_first = (field.field_daily_weather.select { |fdw| fdw.date == Date.parse('2011-06-19') }).first
    assert(fdw_first)
    fdw_first.ad = MID_AD
    fdw_first.save!
    fdw_second = fdw_first.succ
    assert_nil(fdw_second.ad)
    fdw_second.ref_et = ET
    fdw_second.save!
    assert(fdw_second.ad, "Should have updated the second fdw to have an ad balance")
    assert_in_delta(-0.68, fdw_second.ad,0.01)
  end
  
  test "update_balances is correct over an interval" do
    field = create_field_with_crop
    date = Date.parse('2011-06-19')
    fdw = (field.field_daily_weather.select { |fdw| fdw.date == date }).first
    assert(fdw)
    fdw.ad = 0.0
    fdw.save!
    span = 19 # days
    span.times do
      fdw = fdw.succ
      fdw.ref_et = ET
      fdw.save!
    end
    assert_equal(date + span, fdw.date)
    assert_in_delta(-4.12, fdw.ad, 0.025)
  end
  
  def equal(fdw1,fdw2)
    fdw1.attributes.each do |attr_name,attr_val|
      assert_equal(attr_val,fdw2[attr_name],"#{attr_name} differs: #{attr_val} vs. #{fdw2[attr_name]}")
    end
  end
  
  def fdw1and2
    fdw_first = FieldDailyWeather.where(:field_id => Field.first[:id]).order(:date).first
    fdw_second = FieldDailyWeather.where(:field_id => fdw_first[:field_id], :date => fdw_first[:date] + 1).first
    [fdw_first,fdw_second]
  end
  
  test "previous and next work" do
    fdw_first,fdw_second = fdw1and2
    assert_equal([], FieldDailyWeather.previous(fdw_first),"First FDW, should have no pred")
    assert_equal([fdw_second], FieldDailyWeather.next(fdw_first),"Second FDW should have first one as pred")
    assert_equal([fdw_first], FieldDailyWeather.previous(fdw_second),"First FDW should have second one as succ")
  end
  
  test "pred and succ work" do
    fdw_first,fdw_second = fdw1and2
    assert_nil(fdw_first.pred,"First FDW, should have no pred")
    assert(equal(fdw_second, fdw_first.succ),"Second FDW should have first one as pred")
    assert_equal(fdw_first, fdw_second.pred,"First FDW should have second one as succ")
  end 
  
  test "todays_page works for day 0" do
    first_field = Field.first
    assert(first_field.field_daily_weather.size > 0,'First field has no fdw!')
    start_date = first_field.field_daily_weather.first.date
    assert_equal(0, FieldDailyWeather.page_for(7,start_date,first_field.field_daily_weather.first.date))
    assert_equal(0, FieldDailyWeather.page_for(7,start_date,first_field.field_daily_weather.first.date + 6))
  end
  
  test "todays_page works with no date passed in" do
    fdw = @field.field_daily_weather
    assert(fdw.size > 0,'First field has no fdw!')
    page_num = FieldDailyWeather.page_for(7,fdw.first.date)
    assert(page_num)
    index = page_num * 7
    assert(index < fdw.size, "Index #{index} larger than fdw size #{fdw.size}")
    (fdw[index,index+6]).detect { |wx| wx.date == Date.today }
  end
  
end
