require 'test_helper'

class FieldDailyWeatherTest < ActiveSupport::TestCase
  include ADCalculator
  WILT = 0.14
  ET = 0.2
  INITIAL_AD = 0.31
  MID_AD = -0.47
  FC = 0.5
  MRZD = 36
  SOIL_MOISTURE=23
  MAD_FRAC=0.5

  def setup
    pivot = pivots(:one)
    assert(pivot, "No pivot!")
    assert_equal(LaiEtMethod, pivot.farm.et_method.class)
    @default_field_params = {:name => 'test field', :pivot => pivots(:one), 
      :perm_wilting_pt => WILT, :field_capacity => FC}
    @default_crop_params = {:name => 'test crop', :emergence_date => Date.civil(2011,05,01),
      :max_root_zone_depth => MRZD, :max_allowable_depletion_frac => MAD_FRAC, 
      :initial_soil_moisture => SOIL_MOISTURE}
    @field = create_field_with_crop(@default_field_params,@default_crop_params)
  end

  def create_field_with_crop(field_params={},crop_params={})
    @default_field_params.each { |k,v| field_params[k] = v unless field_params[k] }
    @default_crop_params.each { |k,v| crop_params[k] = v unless crop_params[k] }
    field = Field.create(field_params)
    field.crops.first.update_attributes(crop_params)
    field.save!
    field
  end
  
  def create_spreadsheet_field_with_crop
    create_field_with_crop({:perm_wilting_pt => WILT, :field_capacity => 0.31},
      {:max_root_zone_depth => 36, :initial_soil_moisture => 31.0})
  end
  
  test "update_balances does something useful" do
    fdw_first = @field.field_daily_weather[50]
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

  def two_day_balance
    field = create_field_with_crop
    field.field_capacity = 0.31
    field.save!
    fdw_first = (field.field_daily_weather.select { |fdw| fdw.date == Date.parse('2011-06-19') }).first
    assert(fdw_first)
    fdw_first.ad = MID_AD
    fdw_first.save!
    fdw_second = fdw_first.succ
    assert_nil(fdw_second.ad)
    fdw_second.ref_et = ET
    fdw_second.save!
    [fdw_first,fdw_second]
  end

  test "update_balances does something correct" do
    fdw_first,fdw_second = two_day_balance
    assert(fdw_second.ad, "Should have updated the second fdw to have an ad balance\n#{fdw_first.inspect}\n#{fdw_second.inspect}")
    assert_in_delta(-0.68, fdw_second.ad,0.01)
    assert_in_delta(20.62, fdw_second.pct_moisture, 0.01)
  end
  
  test "balance_calcs works" do
    fdw_first,fdw_second = two_day_balance
    expected_attribs = [:adj_et,:deep_drainage,:calculated_pct_moisture,:ad]
    attribs = fdw_second.balance_calcs
    assert_equal(expected_attribs.size, attribs.size,"Wrong number of attribs returned by balance_calcs")
    expected_attribs.each { |attrib| assert(attribs[attrib], "Expected #{attrib} in the balance_calcs has") }
    assert(attribs, "balance_calcs should have returned something")
    assert_equal(Hash, attribs.class, "balance_calcs should have returned a Hash")
    # puts attribs.inspect
    # puts fdw_second.inspect
    attribs.each { |attrib,val| assert_equal(fdw_second[attrib], val,"FDW should have had same value for #{attrib.to_s}") }
  end
  
  test "moisture_at_ad_min is correct" do
    field = create_field_with_crop
    field.field_capacity = 0.31
    field.save!
    crop = field.current_crop
    fc = field.field_capacity
    pwp = field.perm_wilting_pt
    mrzd = crop.max_root_zone_depth
    assert_equal(0.31, fc)
    assert_equal(36.0, mrzd)
    ad_max = ad_max_inches(crop.max_allowable_depletion_frac,taw(fc,pwp,mrzd))
    assert_in_delta(3.06, ad_max, 0.01)
    assert_in_delta(22.5, pct_moisture_at_ad_min(fc, ad_max, mrzd), 0.01)
  end
  
  test "update_balances is correct over an interval" do
    field = create_field_with_crop
    date = Date.parse('2011-06-19')
    fdw = (field.field_daily_weather.select { |fdw| fdw.date == date }).first
    assert(fdw)
    fdw.ad = MID_AD
    fdw.save!
    span = 19 # days
    span.times do
      fdw = fdw.succ
      fdw.ref_et = ET
      fdw.save!
    end
    assert_equal(date + span, fdw.date)
    assert_in_delta(-4.58, fdw.ad, 0.025)
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
    assert_equal(1, FieldDailyWeather.page_for(7,start_date,first_field.field_daily_weather.first.date))
    assert_equal(1, FieldDailyWeather.page_for(7,start_date,first_field.field_daily_weather.first.date + 6))
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
  
  test "can create spreadsheet-identical field" do
    field = create_spreadsheet_field_with_crop
    assert(field, "Field was not created")
    assert((fdw = field.field_daily_weather) && fdw.size > 0, "FDW nil or no records")
    assert_equal(LaiEtMethod, field.et_method.class)
    n_days = 40
    # puts fdw[0].inspect
    emergence_day = 30 # May 1, the default
    fdw[emergence_day].ref_et = ET
    assert(fdw[emergence_day].save)
    n_days.times { |day|  fdw[emergence_day + day].ref_et = ET; fdw[emergence_day + day].save! }
    # this is effed: why should I have to offset it by three places?
    spreadsheet_numbers = [3.06, 3.06, 3.06,
      3.06, 3.06, 3.06, 3.06, 3.06, 3.06, 3.06, 3.06, 3.06, 3.06, 
      3.06, 3.06, 3.06, 3.05, 3.05, 3.05, 3.04, 3.03, 3.02, 3.00,
      2.99, 2.96, 2.93, 2.90, 2.85, 2.80, 2.74, 2.67, 2.60, 2.51,
      2.41, 2.30, 2.19, 2.06, 1.92, 1.77, 1.62, 1.46, 1.29, 1.11
     ]
    n_days.times { |day| assert_in_delta(spreadsheet_numbers[day], fdw[emergence_day + day].ad, 0.01,"Wrong AD number for day #{day}") }
  end
  
  test "can call fdw#summary" do
    field_id = Field.first[:id]
    assert(FieldDailyWeather.summary(field_id), "Failure message.")
  end

  def projected_ad_test(start_days_back)
    finish_days_back = start_days_back + 6
    field = create_spreadsheet_field_with_crop
    assert_not_nil(field.field_daily_weather)
    assert_not_nil(field.field_daily_weather[finish_days_back])
    fdw = field.field_daily_weather[start_days_back..finish_days_back]
    fdw.each { |e| e.ref_et = ET; e.save! }
    adj_ets = fdw.collect { |e| e.adj_et }
    max_adj_et = adj_ets.max
    # set the last day's AD balance to a known quantity
    known_ad = 2.0
    fdw[-1].ad = known_ad
    assert_not_nil(fdw)
    projected = FieldDailyWeather.projected_ad(fdw)
    assert_not_nil(projected)
    assert_equal([known_ad - max_adj_et, known_ad - 2*max_adj_et],projected,"Ad recs were #{fdw.collect {|fdw| fdw.ad}.inspect},#{projected.inspect}")
  end
  
  test "projected_ad works" do
    projected_ad_test(-7)
  end
  
  test "projected_ad offset by 2 days still works" do
    projected_ad_test(-9)
  end
end
