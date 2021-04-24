require 'test_helper'

class FieldDailyWeatherTest < ActiveSupport::TestCase
  include ADCalculator
  WILT = 0.14
  ET = 0.2
  ADJ_ET_NO_PCT_COVER = 0.01 # The adjusted ET calc yields 0.01 adj when ref 0.2 and 0 pct cover
  INITIAL_AD = 0.31
  MID_AD = -0.47
  FC = 0.5
  MRZD = 36
  SOIL_MOISTURE=23
  MAD_FRAC=0.5

  def setup
    pivot = pivots(:one)
    assert(pivot, "No pivot!")
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
    puts "about to create field ******************* "
    field = Field.create(field_params)
    # puts "********* create done, about to update crop with needed params"
    field.crops.first.update(crop_params)
    # puts "******** crop update done"
    # puts field.inspect
    # puts "about to save the field *************"
    # field.save!
    # puts "*********** saved"
    # puts "After save, first FDW is #{field.field_daily_weather[0].inspect}"
    field.field_daily_weather.reload
    # puts "After reload, first FDW is #{field.field_daily_weather[0].inspect}"
    field
  end
  
  def create_spreadsheet_field_with_crop
    create_field_with_crop({:perm_wilting_pt => WILT, :field_capacity => 0.31},
      {:max_root_zone_depth => 36, :initial_soil_moisture => 31.0})
  end
  
  test "create_field_with_crop creates a sensible field" do
    field = create_field_with_crop
    puts("field_capacity: #{field.field_capacity}, perm_wilting_pt: #{field.perm_wilting_pt}, mrzd: #{field.current_crop.max_root_zone_depth}")
    puts("mad_frac: #{field.current_crop.max_allowable_depletion_frac}")
    
    assert_in_delta(2.88, field.ad_max, 0.001)
    assert_equal(LaiEtMethod, field.et_method.class)
    assert_equal(2.88, field.field_daily_weather[0].ad)
  end

  test "LAI field and crop have correct attribs" do
    Field.delete_all
    field = create_field_with_crop({et_method: Field::LAI_METHOD})
    assert_in_delta(FC, field.field_capacity, 2 ** -20,"Created field has wrong field capacity")
    assert_in_delta(WILT, field.perm_wilting_pt, 2 ** -20,"Created field has wrong perm wilting pt")
    assert_in_delta(MRZD, field.current_crop.max_root_zone_depth, 2 ** -20,"Created field has wrong max rootzone depth")
    assert_in_delta(MAD_FRAC, field.current_crop.max_allowable_depletion_frac, 2 ** -20,"Created field has wrong max AD fraction")
    assert_in_delta(6.48, field.ad_max, 2 ** -20,"Created field has wrong max AD")
  end
  
  test "update_balances does something useful" do
    assert_equal("Pct Cover", @field.et_method_name)
    fdw_first = @field.field_daily_weather[50]
    orig_ad = fdw_first.ad
    assert_not_in_delta(0.0,orig_ad,0.1)
    assert(fdw_first.field, "Field daily weather should have a field! #{fdw_first.inspect}")
    fdw_first.ref_et = ET
    fdw_first.save!                        
    puts "saved the first day, it's now #{fdw_first.inspect}"; $stdout.flush
    fdw_second = @field.field_daily_weather[51]
    assert(fdw_second.field, "Field daily weather should have a field! #{fdw_second.inspect}")
    fdw_second.ref_et = ET
    fdw_second.save
    @field.do_balances
    @field.field_daily_weather.reload
    assert_not_in_delta(0.0,fdw_second.adj_et,0.001)
    assert_in_delta(2.871317560945107, fdw_first.ad, 2 ** -20)
    assert_in_delta(2.859815564795565, fdw_second.ad, 2 ** -20)
  end
  
  test "newly-created fdw should have zero rain and irrig" do
    fdw = FieldDailyWeather.create(:date => '2011-05-01')
    assert_equal(0.0, fdw.rain)
    assert_equal(0.0, fdw.irrigation)
  end

  def two_day_balance
    field = create_field_with_crop
    field.field_capacity = 0.31
    fdw_first = (field.field_daily_weather.select { |fdw| fdw.date == Date.parse('2011-06-19') }).first
    assert(fdw_first)
    fdw_second = fdw_first.succ
    fdw_second.ref_et = ET
    field.save!
    [fdw_first,fdw_second]
  end

  test "update_balances does something correct" do
    fdw_first,fdw_second = two_day_balance
    assert(fdw_second.ad, "Should have updated the second fdw to have an ad balance\n#{fdw_first.inspect}\n#{fdw_second.inspect}")
    assert_in_delta(2.88, fdw_second.ad,0.01)
    assert_in_delta(30.0, fdw_second.pct_moisture, 0.01)
  end
  
  # unless and until I go back to the version of FDW that uses this method, this test is obviated
  # test "balance_calcs works" do
  #   fdw_first,fdw_second = two_day_balance
  #   expected_attribs = [:adj_et,:deep_drainage,:calculated_pct_moisture,:ad]
  #   attribs = fdw_second.balance_calcs
  #   assert_equal(expected_attribs.size, attribs.size,"Wrong number of attribs returned by balance_calcs")
  #   expected_attribs.each { |attrib| assert(attribs[attrib], "Expected #{attrib} in the balance_calcs has") }
  #   assert(attribs, "balance_calcs should have returned something")
  #   assert_equal(Hash, attribs.class, "balance_calcs should have returned a Hash")
  #   # puts attribs.inspect
  #   # puts fdw_second.inspect
  #   attribs.each { |attrib,val| assert_equal(fdw_second[attrib], val,"FDW should have had same value for #{attrib.to_s}") }
  # end
  
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
    emerg_fdw = field.field_daily_weather[field.fdw_index(field.current_crop.emergence_date)]
    assert_in_delta(2.88, emerg_fdw.ad, 2 ** -20)
    assert_in_delta(30.0, emerg_fdw.pct_moisture, 2 ** -20)
    date = Date.parse('2011-06-01')
    fdw = nil
    (0..20).each do |ii|
      next_date = date + ii
      fdw = field.field_daily_weather[field.fdw_index(next_date)]
      fdw.ref_et = ET
      fdw.save!
    end
    field.do_balances
    field.field_daily_weather.reload
    results = {
      '2011-06-01' => 2.8021330318729656,
      '2011-06-02' => 2.7144027536682205,
      '2011-06-03' => 2.6166037891798135,
      '2011-06-04' => 2.508672836303241,
      '2011-06-05' => 2.3906885909477955,
      '2011-06-06' => 2.2628654535020543,
      '2011-06-07' => 2.125541620110975,
      '2011-06-08' => 1.9791625627440417,
      '2011-06-09' => 1.8242611864650171,
      '2011-06-10' => 1.6614360950656148,
      '2011-06-11' => 1.4913293936482837,
      '2011-06-12' => 1.3146053246069636,
      '2011-06-13' => 1.1319308023810533,
      '2011-06-14' => 0.9439586212866538,
      '2011-06-15' => 0.7513137999484009,
      '2011-06-16' => 0.5545832309830716,
      '2011-06-17' => 0.3543085524438367,
      '2011-06-18' => 0.15098196427376795,
      '2011-06-19' => -0.05495541566294876,
      '2011-06-20' => -0.26311312849744134,
    }
    (0..20).each do |ii|
      next_date = date + ii
      fdw = field.field_daily_weather[field.fdw_index(next_date)]
      expected_ad = results[next_date.to_s]
      assert_in_delta(expected_ad, fdw.ad, 2 ** -20,"AD wrong for #{fdw.date}") if expected_ad
    end
  end
  
  test "update_balances is correct for pct_cover when interval is based at emergence" do
    pivot = pivots(:other)
    field = create_field_with_crop({pivot: pivot, field_capacity: FC, perm_wilting_pt: PWP, et_method: Field::PCT_COVER_METHOD},{max_allowable_depletion_frac: MAD})
    assert_equal("Pct Cover", field.et_method_name)
    emi = emergence_index(field)
    assert_equal(30, emi)
    span = 19
    # set % cover. We want all 100%s for ease of checking balance calcs (i.e. adj_et == ref_et), so start with
    # day after emergence, set that, then "span" days out; should fill the range with values linearly interpolated
    # from 100.0 to 100.0
    start_fdw = field.field_daily_weather[emi+ 1]
    start_fdw.entered_pct_cover = 100.0
    start_fdw.save!
    field.pct_cover_changed(start_fdw)
    span_fdw = field.field_daily_weather[emi+span]
    span_fdw.entered_pct_cover = 100.0
    span_fdw.save!
    field.pct_cover_changed(span_fdw)
    field.field_daily_weather.reload
    covers = []
    (span+1).times do |day|
      covers << field.field_daily_weather[emi+day].pct_cover
    end
    
    span.times do |day|
      fdw = field.field_daily_weather[emi+day]
      if day == 0
        assert_in_delta(0.0, fdw.pct_cover, 2 ** -20,"Emergence (#{fdw.date}) should have no pct cover")
      else
        assert_in_delta(100.0, fdw.pct_cover, 2 ** -20,"#{fdw.date} had wrong pct cover\n#{covers.inspect}") if day > 0 # Emergence day is 0 by defn
      end
      fdw.ref_et = ET
      fdw.save!
    end
    field.do_balances
    field.field_daily_weather.reload
    STARTING_AD = 2.7 - field.field_daily_weather[emi].adj_et # It's measured at the end of the first day
    span.times do |day|
      fdw = field.field_daily_weather[emi + day]
      # if day == 0
        # assert_in_delta(STARTING_AD - ADJ_ET_NO_PCT_COVER, fdw.ad, 0.0001,"Emergence date should start at field capacity AD")
      # else
        assert_in_delta(STARTING_AD - ADJ_ET_NO_PCT_COVER - (day * ET), fdw.ad, 0.0001,"Day #{day} (#{fdw.date}) has incorrect balance")
      #end
    end
  end
  
  # Spew debug info to stdout (for failed assertions)
  def dbgprt(fdw,field)
    "  #{fdw.inspect},  field is #{field.inspect}, crop is #{field.current_crop.inspect}"
  end
  
  ET = 0.2
  FC = 0.3
  PWP = 0.15
  MAD = 0.5
  # deep drainage occurs when we go over field capacity -- check an LAI field first...
  test "deep drainage with LAI" do
    field = create_field_with_crop({field_capacity: FC, perm_wilting_pt: PWP, et_method: Field::LAI_METHOD},{max_allowable_depletion_frac: MAD})
    assert_equal("LAI",field.et_method_name)
    fdw = field.field_daily_weather.first
    assert(fdw,'Should be able to get the first day of FDW')
    fdw.ref_et = ET
    fdw.save! # Should now have an AD calculated
    assert_in_delta(field.ad_max, fdw.ad, 2 ** -10, "AD should start out at max ad in inches #{field.ad_max} but was #{fdw.inspect}")
    fdw.ref_et = ET
    fdw.leaf_area_index = 1.6 # Should yield adj. ET == ref. ET
    fdw.irrigation = 0.3 # Add some irrigation at FC, 0.2 balanced by ET, 0.1 should drain out
    fdw.save!
    field.do_balances
    assert_in_delta(ET, fdw.adj_et, 2 ** -10,"An LAI of 1.6 should yield an adjusted ET same as ref ET"+dbgprt(fdw,field))
    assert_in_delta(0.1, fdw.deep_drainage, 2 ** -10,'Should have gotten some deep drainage from adding irrigation at FC'+dbgprt(fdw,field))
    assert_in_delta(field.ad_max, fdw.ad, 2 ** -10,'Deep drainage should leave the field at FC'+dbgprt(fdw,field))
  end
  
  # deep drainage occurs when we go over field capacity -- now a percent cover field.
  test "deep drainage with percent cover" do
    pivot = pivots(:other)
    field = create_field_with_crop({pivot: pivot, field_capacity: FC, perm_wilting_pt: PWP, et_method: Field::PCT_COVER_METHOD},{max_allowable_depletion_frac: MAD})
    fdw = field.field_daily_weather.first
    assert(fdw,'Should be able to get the first day of FDW')
    fdw.ref_et = ET
    fdw.save!
    field.do_balances # Should now have an AD calculated
    assert_in_delta(field.ad_max - ADJ_ET_NO_PCT_COVER, fdw.ad, 2 ** -10, "AD should start out at max ad in inches"+dbgprt(fdw,field))
    assert_in_delta(100*field.field_capacity, fdw.calculated_pct_moisture, 2 ** -10)
    # Now look at emergence date so's to get adj_et numbers with a percent cover
    emi = field.fdw_index(field.current_crop.emergence_date)
    fdw = field.field_daily_weather[emi]
    e_plus_one_fdw = field.field_daily_weather[emi + 1]
    e_minus_one_fdw = field.field_daily_weather[emi - 1]
    assert(fdw,'Should be able to get emergence-day FDW')
    fdw.ref_et = ET
    e_plus_one_fdw.ref_et = ET
    e_plus_one_fdw.entered_pct_cover = 100.0 # Should yield adj. ET == ref. ET
    fdw.save!
    field.do_balances
    # Should this be at field capacity? Or should nonzero adjusted ETs pre-emergence have drawn it down?
    adj_et_sum = field.field_daily_weather[0..emi].inject(0.0) { |sum, an_fdw| sum + an_fdw.adj_et }
    assert(adj_et_sum > 0.0)
    assert_in_delta(field.ad_max - adj_et_sum, fdw.ad, 2 ** -10, "AD should start out at max ad in inches decremented by #{adj_et_sum}"+dbgprt(fdw,field))
    # assert_in_delta(field.field_capacity * 100.0, fdw.pct_moisture, 2 ** -20,"FDW should be at FC (#{field.field_capacity * 100.0}) now:\n  #{fdw.inspect}\nprevious day:\n  #{e_minus_one_fdw.inspect}")
    # Add irrigation to get it back up to ad_max, plus 0.1; the 0.1 should drain out
    e_plus_one_fdw.irrigation = (field.ad_max - e_plus_one_fdw.ad) + 0.1
    e_plus_one_fdw.save!
    field.do_balances
    assert_in_delta(ET, e_plus_one_fdw.adj_et, 2 ** -10,"100% cover should yield an adjusted ET same as ref ET"+dbgprt(fdw,field))
    assert_in_delta(0.1, e_plus_one_fdw.deep_drainage, 2 ** -10,"Should have gotten some deep drainage from adding irrigation at FC (#{field.field_capacity * 100.0}) #{e_plus_one_fdw.inspect}")
    assert_in_delta(field.ad_max, e_plus_one_fdw.ad, 2 ** -10,'Deep drainage should leave the field at FC'+dbgprt(fdw,field))
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
    assert_equal(field.field_capacity * 100.0, fdw[0].pct_moisture,"First FDW should be set to field capacity")
    assert_equal("LAI", field.et_method_name)
    n_days = 40
    # puts fdw[0].inspect
    emergence_day = 30 # May 1, the default
    fdw[emergence_day].ref_et = ET
    assert(fdw[emergence_day].save)
    assert_equal(field.field_capacity * 100.0, fdw[emergence_day].pct_moisture,"Emergence FDW should be set to field capacity")
    n_days.times { |day|  fdw[emergence_day + day].ref_et = ET; fdw[emergence_day + day].save! }
    field.do_balances
    # this is effed: why should I have to offset it by three places?
    spreadsheet_numbers = [3.06, 3.06, 3.06,                         # 0-2
      3.06, 3.06, 3.06, 3.06, 3.06, 3.06, 3.06, 3.06, 3.06, 3.06,    # 3-12
      3.06, 3.06, 3.06, 3.05, 3.05, 3.05, 3.04, 3.03, 3.02, 3.00,    # 13-22
      2.99, 2.96, 2.93, 2.90, 2.85, 2.80, 2.74, 2.67, 2.60, 2.51,    # 23-32
      2.41, 2.30, 2.19, 2.06, 1.92, 1.77, 1.62, 1.46, 1.29, 1.11     # 33-42
     ]
    n_days.times { |day| assert_in_delta(spreadsheet_numbers[day], fdw[emergence_day + day].ad, 0.01,"Wrong AD number (#{fdw[emergence_day + day].ad}) for day #{day}") }
  end
  
  test "can call fdw#summary" do
    field_id = Field.first[:id]
    assert(FieldDailyWeather.summary(field_id), "Failure message.")
  end
  
  test "summary has the fields I expect" do
    pivot = pivots(:other)
    season_year = pivot.cropping_year
    field = create_field_with_crop({pivot: pivot, field_capacity: FC, perm_wilting_pt: PWP, et_method: Field::PCT_COVER_METHOD},{max_allowable_depletion_frac: MAD})
    summary = FieldDailyWeather.summary(field[:id])
    [:rain,:irrigation,:deep_drainage,:adj_et].each do |column|
      assert_equal(0.0, summary[column],"#{column.to_s} not found in summary  #{summary.inspect}  field: #{field.inspect}")
    end
    date = field.field_daily_weather[-1].date
    assert_equal(date.to_s, summary[:date].to_s,"Wrong date for summary")
  end
  
  test "summary produces sensible results" do
    pivot = pivots(:other)
    season_year = pivot.cropping_year
    field = create_field_with_crop({pivot: pivot, field_capacity: FC, perm_wilting_pt: PWP, et_method: Field::PCT_COVER_METHOD},{max_allowable_depletion_frac: MAD})
    # Pull the summary. Of course there should be no nonzero values, so it should sum to all zeroes.
    summary = FieldDailyWeather.summary(field[:id])
    [:adj_et,:rain,:irrigation,:deep_drainage].each { |thing| assert_equal(0.0, summary[thing]) }
    emi = field.fdw_index(field.current_crop.emergence_date)
    n_fdw = field.field_daily_weather[emi..-1].size
    vals = {ref_et: 0.2, entered_pct_cover: 60.0, rain: 0.3, irrigation: 0.4}
    ADJ_ET = 0.176493
    expected_adj_et = ADJ_ET * n_fdw                # adjusted ET for 60% cover and ref_et 0.2
    expected_rain = vals[ :rain] * n_fdw              # rains 0.3 every day
    expected_irrigation = vals[ :irrigation] * n_fdw  # irrigate 0.4 every day
    expected_deep_drainage = 0.523507 * n_fdw         # Which, all together, should take us over FC so there's DD
    # Iterate through from emergence to the end of the season
    number_set = 0
    adj_et_sum = 0.0
    field.field_daily_weather[emi..-1].each do |fdw|
      vals.each do |param,val|
        fdw[param] = val
      end
      number_set += 1
      adj_et_sum += ADJ_ET
    end
    assert_equal(n_fdw,number_set,"Did not set values for the correct number of FDW records.")
    assert_in_delta(expected_adj_et,adj_et_sum,10 ** -8,"Wrong cumulative adj ET")
    field.save!
    field.field_daily_weather.reload
    field.field_daily_weather[emi..-1].each do |fdw|
      assert_in_delta(ADJ_ET,fdw[:adj_et],10 ** -8,"adj et for #{fdw[:date]} was wrong")
      assert_in_delta(n_fdw,field.field_daily_weather[emi..-1].size,10 ** -8)
    end 
    summary = FieldDailyWeather.summary(field[:id])
    # Check all of the four params like this one
    #puts expected_adj_et.inspect
    #puts summary[:adj_et].inspect
    assert_equal(n_fdw,summary[:count],"Did not set values for the correct number of FDW records. #{n_fdw}, #{summary.inspect}")
    assert_in_delta(expected_adj_et,summary[:adj_et], 10 ** -8, "Expected Adj ET wrong, adj et for first day #{field.field_daily_weather[emi][:adj_et]}, last day  #{field.field_daily_weather[-1][:adj_et]}")
    assert_in_delta(expected_rain,summary[:rain], 10 ** -8, "Expected Rain wrong, Rain for first day #{field.field_daily_weather[emi][:rain]}, last day  #{field.field_daily_weather[-1][:rain]}")
    assert_in_delta(expected_irrigation,summary[:irrigation], 10 ** -8, "Expected Irrigation wrong, irrigation for first day #{field.field_daily_weather[emi][:irrigation]}, last day  #{field.field_daily_weather[-1][:irrigation]}")
    assert_in_delta(expected_deep_drainage,summary[:deep_drainage], 10 ** -8, "Expected deep drainage wrong, deep drainage for first day #{field.field_daily_weather[emi][:deep_drainage]}, last day  #{field.field_daily_weather[-1][:deep_drainage]}")

    # Change harvest/kill date for crop, but use the same date 
    field.current_crop.harvest_or_kill_date = field.field_daily_weather[-1].date
    field.save!
    # Pull the summary
    summary = FieldDailyWeather.summary(field[:id])
    # Rerun the four assertions with the same numbers, should yield the same results
    assert_in_delta(expected_adj_et,summary[:adj_et], 1.0, "Expected Adj ET wrong")
    assert_in_delta(expected_rain,summary[:rain], 10 ** -8, "Expected Rain wrong, Rain for first day #{field.field_daily_weather[emi][:rain]}, last day  #{field.field_daily_weather[-1][:rain]}")
    assert_in_delta(expected_irrigation,summary[:irrigation], 10 ** -8, "Expected Irrigation wrong, irrigation for first day #{field.field_daily_weather[emi][:irrigation]}, last day  #{field.field_daily_weather[-1][:irrigation]}")
    assert_in_delta(expected_deep_drainage,summary[:deep_drainage], 10 ** -8, "Expected deep drainage wrong, deep drainage for first day #{field.field_daily_weather[emi][:deep_drainage]}, last day  #{field.field_daily_weather[-1][:deep_drainage]}")
  end
  
  test "summary produces sensible results over a subset of the season" do
    DAYS_FROM_SEASON_END = 50
    pivot = pivots(:other)
    season_year = pivot.cropping_year
    field = create_field_with_crop({pivot: pivot, field_capacity: FC, perm_wilting_pt: PWP, et_method: Field::PCT_COVER_METHOD},{max_allowable_depletion_frac: MAD})
    emi = field.fdw_index(field.current_crop.emergence_date)
    # simulate a summary taken on a particular day by specifying a finish date (the production code
    # defaults the finish date to "today" if we're looking at a current-year field)
    # n_fdw = field.field_daily_weather.size - emi - DAYS_FROM_SEASON_END #This gives wrong size. 
    n_fdw = field.field_daily_weather[emi..-1].size - DAYS_FROM_SEASON_END
    finish_fdw = field.field_daily_weather[-DAYS_FROM_SEASON_END]
    finish_date = finish_fdw.date
    vals = {ref_et: 0.2, entered_pct_cover: 60.0, rain: 0.3, irrigation: 0.4}
    results = {
      adj_et: 0.176493 * n_fdw,               # adjusted ET for 60% cover and ref_et 0.2
      rain: vals[:rain] * n_fdw,              # rains 0.3 every day
      irrigation: vals[:irrigation] * n_fdw,  # irrigate 0.4 every day
      deep_drainage: 0.523507 * n_fdw         # Which, all together, should take us over FC so there's DD
    }
    # Iterate through from emergence to the end of the season
    # This should throw off the sums if they're not taking the finish date into account
    field.field_daily_weather[emi..-1].each do |fdw|
      vals.each do |param,val|
        fdw[param] = val
      end
    end
    field.save!
    field.field_daily_weather.reload
    summary = FieldDailyWeather.summary(field[:id],field.current_crop.emergence_date,finish_date)
    results.each do |param,result|
      assert_in_delta(result, summary[param], 1.4,
      "#{param.to_s} as of #{finish_date} (#{n_fdw} days) should have been #{result} " +
        "at #{sprintf("%0.2f",finish_fdw[param])} per day"
      )
    end
    assert_in_delta(summary[:rain] + summary[:irrigation], summary[:adj_et] + summary[:deep_drainage], 2 ** -20)
  end
  
  def fdws_from_emergence(field,n_fdws=3)
    emi = field.fdw_index(field.current_crop.emergence_date)
    fdws = []
    n_fdws.times { |ii| fdws << field.field_daily_weather[emi+ii] }
    fdws
  end
  
  test "CSV production works" do
    pivot = pivots(:other)
    field = create_field_with_crop({pivot: pivot, field_capacity: FC, perm_wilting_pt: PWP, et_method: Field::PCT_COVER_METHOD},{max_allowable_depletion_frac: MAD})
    fdws = fdws_from_emergence(field)
    assert_equal(Array, fdws.class)
    assert_equal(3, fdws.size)
    fdws.each_with_index do |fdw,ii|
      fdw.ref_et = 0.3 + ii/100.0
      fdw.rain = 0.2 + ii/100.0
      fdw.irrigation = 1.0 + ii/100.0
    end
    field.save!
    field.field_daily_weather.reload
    fdws = fdws_from_emergence(field)
    assert(csv = fdws[1].to_csv)
    assert_equal("2011-05-02,0.31,2.70,30.00,0.00,0.21,1.01,0.01,1.21", csv)
  end
  
  test "moisture method works" do
    field=create_field_with_crop({perm_wilting_pt: 0.05, field_capacity: 0.15})
    field.current_crop.max_root_zone_depth = 15.0
    field.save!
    fdw = field.field_daily_weather[60]
    total_available_water = taw(
      field.field_capacity, field.perm_wilting_pt, field.current_crop.max_root_zone_depth
    )

    assert_in_delta(0.75, fdw[:ad], 2 ** -20)
    assert_in_delta(15.0, fdw.moisture(
      field.current_crop.max_allowable_depletion_frac,
      total_available_water,
      field.perm_wilting_pt,
      field.field_capacity,
      fdw[:ad],
      field.current_crop.max_root_zone_depth
      ),0.00001
    )
    fdw.ad *= -8
    fdw.save!
    field.field_daily_weather.reload
    fdw = field.field_daily_weather[60]
    assert_in_delta(0.05, fdw.moisture(
      field.current_crop.max_allowable_depletion_frac,
      total_available_water,
      field.perm_wilting_pt,
      field.field_capacity,
      fdw[:ad],
      field.current_crop.max_root_zone_depth
      ), 2 ** -20)
    assert_in_delta(0.05, fdw.calculated_pct_moisture, 2 ** -20)
  end
end
