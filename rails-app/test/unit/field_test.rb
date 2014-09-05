require 'test_helper'


class FieldTest < ActiveSupport::TestCase
  
  def setup
    @pcf = fields(:one)
    @pct_cover_method = EtMethod.find_by_type('PctCoverEtMethod')
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
    assert_nothing_raised(Exception) { @pcf.ad_max_inches(0.1,0.5) }
    assert_nothing_raised(Exception) { @pcf.ad_max_inches(0.1,0.5) }
    fc = pwp = mrzd = mad_frac = taw = ad_max = daily_rain = daily_irrig = adj_et = prev_daily_ad = delta_stor = 0.5
    pct_moisture_at_ad_min = ad = pct_moisture_obs = mad_frac = 0.5
    assert_nothing_raised(Exception) {  @pcf.taw(fc, pwp, mrzd) }
    assert_nothing_raised(Exception) {  @pcf.ad_max_inches(mad_frac, taw) }
    assert_nothing_raised(Exception) {  @pcf.pct_moisture_at_ad_min(fc, ad_max, mrzd) }
    assert_nothing_raised(Exception) {  @pcf.change_in_daily_storage(daily_rain, daily_irrig, adj_et) }
    assert_nothing_raised(Exception) {  @pcf.daily_ad(prev_daily_ad, delta_stor,mad_frac,taw) }
    assert_nothing_raised(Exception) {  @pcf.pct_moisture_from_ad(pwp, fc, ad_max, ad, mrzd, pct_moisture_obs) }
    assert_nothing_raised(Exception) {  @pcf.daily_deep_drainage_volume(ad_max, prev_daily_ad, delta_stor) }
    assert_nothing_raised(Exception) {  @pcf.daily_ad_from_moisture(mad_frac,taw,mrzd,pct_moisture_at_ad_min,pct_moisture_obs) }
  end
  
  FC = 0.3
  PWP = 0.15
  MAD_FRAC = 0.5
  
  def create_a_field(pivot_id=Pivot.first[:id])
    f = Field.create(field_capacity: FC, perm_wilting_pt: PWP, pivot_id: pivot_id)
    assert_equal(f.current_crop.max_allowable_depletion_frac, MAD_FRAC)
    f
  end
  
  # test "moisture defaults to field capacity on creation" do
  #   field = create_a_field
  #   assert_equal(100*field.field_capacity, field.field_daily_weather[0].calculated_pct_moisture,
  #     "Expected first FDW to be at FC, but was:\n" + field.inspect + "\n" + field.field_daily_weather[0].inspect)
  #   fdw = field.field_daily_weather.select { |f| f.date == field.current_crop.emergence_date }.first
  #   assert_equal(100*field.field_capacity, fdw.calculated_pct_moisture,
  #     "Expected emergence FDW to be at FC, but was:\n" + field.inspect + "\n" + fdw.inspect)
  # end

  def yes_moisture_for_fdw_0_and_emerg_are_at_fc(field)
    assert_in_delta(100*field.field_capacity, field.field_daily_weather[0].calculated_pct_moisture,
      0.00001,
      "Expected first FDW to be at FC, but was:\n" + field.inspect + "\n" + field.field_daily_weather[0].inspect)
    fdw = field.field_daily_weather.select { |f| f.date == field.current_crop.emergence_date }.first
    assert_equal(100*field.field_capacity, fdw.calculated_pct_moisture,
      "Expected emergence FDW to be at FC, but was:\n" + field.inspect + "\n" + fdw.inspect)
  end
  
  test "moisture defaults to field capacity on creation" do
    field = create_a_field
    yes_moisture_for_fdw_0_and_emerg_are_at_fc(field)
  end
  
  test "moisture changes to field capacity on update" do
    field = create_a_field
    field.field_capacity_pct = (FC * 0.8) * 100.0
    field.save!
    yes_moisture_for_fdw_0_and_emerg_are_at_fc(field)
  end
  
  test "moisture changes to field capacity if updating the raw FC too" do
    field = create_a_field
    field.field_capacity = FC * 0.5
    field.save!
    yes_moisture_for_fdw_0_and_emerg_are_at_fc(field)
  end

  def moisture_changes(field)
    emi = emergence_index(field)
    unexpected = {
      0 => field.field_daily_weather[0].pct_moisture,
      emi => field.field_daily_weather[emi].pct_moisture
    }
    assert_in_delta(unexpected[0], unexpected[emi], 2 ** -20)
    yield(field)
    unexpected.each do |fdw_index,value|
      fdw = field.field_daily_weather[fdw_index]
      assert_not_in_delta(
        value,
        fdw.pct_moisture,0.0001,
        "Changing PWP should have changed FDW moisture for #{fdw.date}"
    )
    end
  end

  def setup_field_with_AD
    field = create_a_field
    field.et_method = @pct_cover_method
    field.save!
    emi = emergence_index(field)
    # before we change anything, fdw[emi] will be at FC, and the next one will be nil
    assert_in_delta(field.field_capacity * 100.0, field.field_daily_weather[emi].pct_moisture, 2 ** -20)
    # assert_nil(field.field_daily_weather[emi+1].pct_moisture) # Field now does balances for all FDW
    # set up a sequence of FDW with ref ET and pct cover, save each one so that balance calcs are initialized
    vals = {
      emi => {:ref_et => 0.2, :entered_pct_cover => 0.0},
      emi+1 => {:ref_et => 0.21, :entered_pct_cover => 10.0},
      emi+2 => {:ref_et => 0.22, :entered_pct_cover => 50.0},
      emi+3 => {:ref_et => 0.19, :entered_pct_cover => 80.0}
    }
    unexpected = {}
    vals.each do |index,attrs|
      fdw = field.field_daily_weather[index]
      fdw.update_attributes(attrs)
      fdw.save!
      unexpected[fdw[:id]] = {:moisture => fdw.pct_moisture, :ad => fdw.ad}
      assert(fdw.pct_moisture)
    end
    assert_equal(0.22, field.field_daily_weather[emi+2].ref_et)
    [field,unexpected]
  end
  
  test "changing FC triggers a balance recalc which changes moisture" do
    field,unexpected = setup_field_with_AD
    # puts "********************* updating FC from #{field.field_capacity} to #{0.5 * FC} **********************"
    # puts "********************* set and save the field, which should update balances **********************"
    field.field_capacity_pct = 100 * 0.6 * FC
    field.save!
    field.field_daily_weather.reload
    unexpected.each do |id,params|
      fdw = FieldDailyWeather.find(id)
      moisture = params[:moisture]
      assert_not_in_delta(moisture,fdw.pct_moisture,0.0001,"Moisture value should have changed for #{fdw.date} when field params did (emergence #{field.current_crop.emergence_date})")
      ad = params[:ad]
      assert_not_in_delta(ad,fdw.ad,0.0001,"AD should have been recalced (and changed) for #{fdw.date} when field params did (emergence #{field.current_crop.emergence_date})")
    end
  end
  
  # FIXME: I think the logic may be wrong for AD/moisture calcs, because the moisture is getting recalced from new AD perhaps?
  # Needs a test for Day 0, and the Web version seems to work fine. What gives?
  test "changing PWP does not change initial moisture, but redoes AD via balance calc" do
    field,unexpected = setup_field_with_AD
    # puts "field.perm_wilting_pt starts at #{field.perm_wilting_pt}"
    field.perm_wilting_pt = 0.98 * FC # Bigger allowable depletion, then
    # puts "field.perm_wilting_pt is now at #{field.perm_wilting_pt}, hopefully triggering balance calcs"
    field.save!
    # puts "after save"
    # Since we just copy over FC on top of moisture, THAT won't change. Check that it hasn't.
    emerg_fdw = field.field_daily_weather[emergence_index(field)]
    # "Unexpected" is a bit of a misnomer here, it actually contains the value that we expect
    emergence_moisture = unexpected[emerg_fdw[:id]][:moisture]
    # Ensure that AD hasn't changed (easier to test than pct_moisture)
    assert_in_delta(field.ad_max - emerg_fdw.adj_et, emerg_fdw.ad, 2 ** -10, "AD should start out at max ad in inches")
    # This is wrong -- moisture should be down by one day's worth
    # assert_in_delta(emergence_moisture, emerg_fdw.pct_moisture,0.0000001,'Emergence moisture should not change, s/b set at FC')
    unexpected.each do |id,params|
      fdw = FieldDailyWeather.find(id)
      ad = params[:ad]
      moisture = params[:moisture]
      unless fdw[:id] == emerg_fdw[:id] # as we saw above, emergence day is a special case
        assert_not_in_delta(moisture,fdw.pct_moisture,0.0001,"Moisture value should have changed for #{fdw.date} when field params did (emergence #{field.current_crop.emergence_date})")
        assert_not_in_delta(ad,fdw.ad,0.0001,"ad value should have changed for #{fdw.date} when field params did (emergence #{field.current_crop.emergence_date})")
      end
    end
  end
  
  test "deep drainage is zero on creation" do
    field = create_a_field
    field.field_daily_weather[50].ref_et = 0.2
    field.field_daily_weather[50].leaf_area_index = 1.9
    field.save!
    fdw_with_dd = 0
    field.field_daily_weather.each do |fdw|
      if fdw.deep_drainage
        assert_in_delta(0.0, fdw.deep_drainage, 2 ** -20,fdw.date)
        fdw_with_dd += 1
      end
    end
    assert(fdw_with_dd > 0, "Should have been some deep drainage numbers")
  end
  
  test "deep drainage is zero for percent cover fields too" do
    pct_pivot = Pivot.all.select { |p| p.farm.et_method.class == PctCoverEtMethod }.first
    field = create_a_field(pct_pivot[:id])
    field.field_daily_weather[50].ref_et = 0.2
    field.field_daily_weather[50].entered_pct_cover = 80.0
    field.save!
    fdw_with_dd = 0
    field.field_daily_weather.each do |fdw|
      if fdw.deep_drainage
        assert_in_delta(0.0, fdw.deep_drainage, 2 ** -20,fdw.date)
        fdw_with_dd += 1
      end
    end
    assert(fdw_with_dd > 0, "Should have been some deep drainage numbers")
  end
  
  ET = 0.2
  
  test "AD defaults to TAW * MAD_FRAC * RZD on creation" do
    field = create_a_field
    assert_in_delta(FC, field.field_capacity, 2 ** -20)
    assert_in_delta(MAD_FRAC, field.current_crop.max_allowable_depletion_frac, 2 ** -20)
    # assert_equal(PctCoverEtMethod, field.et_method.class)
    fdw = field.field_daily_weather.select { |f| f.date == field.current_crop.emergence_date }.first
    assert(fdw, "Field should have FDW on creation")
    assert(fdw.ad,"Emergence FDW should have an AD, because the field should have set it upon creation")
    second_fdw = field.field_daily_weather.select { |f| f.date == field.current_crop.emergence_date + 1 }.first
    assert(second_fdw, "Should have a successor to fdw")
    fdw.ref_et = ET
    field.save!
    expected_taw = (field.field_capacity - field.perm_wilting_pt) * field.current_crop.max_root_zone_depth
    assert_in_delta(5.4, expected_taw, 2 ** -20)
    expected_ad = field.current_crop.max_allowable_depletion_frac * expected_taw
    assert_in_delta(2.7, expected_ad, 2 ** -10)
    assert_in_delta(2.7, fdw.ad, 2 ** -10)
    second_fdw.ref_et = ET
    second_fdw.leaf_area_index = 1.605 # Empirically determined to yield adj_et ~= ref_et
    field.save!
    assert_in_delta(ET, second_fdw.adj_et, 2 ** -10)
    assert_in_delta(expected_ad - second_fdw.adj_et, second_fdw.ad, 2 ** -10)
  end
  
  test "calculated_pct_moisture is correct on creation" do
    pct_pivot = Pivot.all.select { |p| p.farm.et_method.class == PctCoverEtMethod }.first
    field = create_a_field(pct_pivot[:id])
    (0..field.field_daily_weather.size-1).each do |day|
      fdw = field.field_daily_weather[day]
      assert_in_delta(100*field.field_capacity, field.field_daily_weather[0].pct_moisture, 2 ** -20,
        "For first day of FDW and emergence date, moisture s/b at field capacity (#{field.field_capacity})"
      )
    end
  end
  
  test "pct_moisture and AD change when FC changes" do
    pct_pivot = Pivot.all.select { |p| p.farm.et_method.class == PctCoverEtMethod }.first
    field = create_a_field(pct_pivot[:id])
    emi = emergence_index(field)
    assert(emi)
    initial_moist = field.field_daily_weather[emi].pct_moisture
    assert(initial_moist > 0.0,"initial moisture for emergence was wrong at #{initial_moist}")
    initial_ad = field.field_daily_weather[emi].ad
    assert(initial_ad > 0.0,"initial ad for emergence was wrong at #{initial_ad}")
  end
  
                                                        
  test "change_in_daily_storage works" do
    assert_equal(0.0, @pcf.change_in_daily_storage(0.0,0.0,0.0))
    assert_equal(-0.2, @pcf.change_in_daily_storage(0.0,0.0,0.2))
    assert_equal(0.2, @pcf.change_in_daily_storage(0.0,0.2,0.0))
    assert_equal(0.2, @pcf.change_in_daily_storage(0.2,0.0,0.0))
    assert_equal(0.4, @pcf.change_in_daily_storage(0.2,0.2,0.0))
    assert_equal(0.0, @pcf.change_in_daily_storage(0.2,0.2,0.4))
  end
  
  test "daily AD works below ad_max" do
    mad_frac = 0.5
    taw = 6.0
    prev_daily_ad = 2.0
    assert_equal(1.5, @pcf.daily_ad(prev_daily_ad,-0.5,mad_frac,taw))
  end
  
  test "daily AD works above ad_max" do
    mad_frac = 0.5
    taw = 6.0
    prev_daily_ad = 10.0
    ad_max = @pcf.ad_max_inches(mad_frac,taw)
    assert_equal(3.0, ad_max)
    assert_equal(ad_max, @pcf.daily_ad(prev_daily_ad,20.0,mad_frac,taw))
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
    field = Field.create(:pivot_id => Farm.first.pivots.first[:id],:field_capacity => 0.4, :perm_wilting_pt => 0.13)
    FieldDailyWeather.destroy_all
    field = Field.find(field[:id])
    start_date,end_date = field.date_endpoints
    n_days = 1 + (end_date - start_date)
    assert(field)
    assert_equal(0, field.field_daily_weather.size)
    field.create_field_daily_weather
    field.save!
    assert_equal(n_days, field.field_daily_weather.size)
  end
  
  test "ensure that field_daily_weather recs are created after field is created" do
    field = Field.create(:pivot_id => Farm.first.pivots.first[:id], :field_capacity => 0.4, :perm_wilting_pt => 0.13)
    start_date,end_date = field.date_endpoints
    n_days = 1 + (end_date - start_date)
    assert_equal(n_days, field.field_daily_weather.size)
  end
  
  test "field_daily_weather for a field all gets deleted when the field goes away" do
    field = Field.create(:pivot_id => Farm.first.pivots.first[:id],:field_capacity => 0.4, :perm_wilting_pt => 0.13)
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
        assert_equal(0.0,fdw.leaf_area_index)
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
    assert(fdw_emergence_date, "Should be a wx record for emergence date #{emergence_date}, earliest #{field.field_daily_weather.first.date}")
    assert_equal(0.0,fdw_emergence_date.leaf_area_index,"Should start out with nothing for LAI on emergence date of #{emergence_date.to_s} for field '#{field.name}'")
  end

  def setup_field_with_emergence
    farm = Farm.first
    assert_equal(LaiEtMethod, farm.et_method.class)
    field = Field.create(
      :pivot_id => farm.pivots.first[:id],:field_capacity => 0.4, :perm_wilting_pt => 0.13,
      :soil_type_id => SoilType.default_soil_type[:id])
    emergence_date = Date.civil(2011,05,01)
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
    assert(fdw_start, "No field daily weather for field")
    start_date = fdw_start.date
    assert_equal(0, field.fdw_index(start_date))
    assert_equal(emergence_date - start_date, field.fdw_index(emergence_date))
  end
  
  def setup_pct_cover_field_with_emergence
    farm = farms(:ricks_other_farm)
    field = Field.create(:pivot_id => farm.pivots.first[:id],:field_capacity => 0.4, :perm_wilting_pt => 0.13,
      et_method: Field::PCT_COVER_METHOD)
    emergence_date = Date.civil(2011,05,01)
    [field,emergence_date]
  end
  
  test "I can get a farm with percent cover" do
    field,emergence_date = setup_pct_cover_field_with_emergence
    assert_equal(field.et_method.class, PctCoverEtMethod,field.pivot.farm.inspect)
  end
  
  test "I can automatically set a range of percent cover" do
    FieldDailyWeather.destroy_all
    field,emergence_date = setup_pct_cover_field_with_emergence
    emi = emergence_index(field)
    assert_equal(0.0, field.field_daily_weather[emi].pct_cover,field.field_daily_weather[emi..emi+10].collect { |fdw| [fdw.date,fdw.pct_cover] }.inspect)
    field.field_daily_weather[emi+9].entered_pct_cover = 9.0
    field.pct_cover_changed(field.field_daily_weather[emi+9])
    field.save! # Triggers do_balances and saves the FDW -- right?
    field = Field.find(field[:id])
    assert_in_delta(1.0, field.field_daily_weather[emi+1].pct_cover, 0.00001,field.field_daily_weather[emi..emi+10].collect { |fdw| [fdw.date,fdw.pct_cover] }.inspect)
    assert_in_delta(8.0, field.field_daily_weather[emi+8].pct_cover, 0.00001,field.field_daily_weather[emi..emi+10].collect { |fdw| [fdw.date,fdw.pct_cover] }.inspect)
    assert_in_delta(9.0, field.field_daily_weather[emi+15].pct_cover, 0.00001,field.field_daily_weather[emi..emi+10].collect { |fdw| [fdw.date,fdw.pct_cover] }.inspect)
  end
  
  test "my automatically-set range does not extend back past emergence" do
    FieldDailyWeather.destroy_all
    field,emergence_date = setup_pct_cover_field_with_emergence
    emi = emergence_index(field)
    index_to_set = emi + 2
    day_before_emergence = emi - 1
    day_after_emergence = emi + 1
    week_after_set = index_to_set + 6
    one_day_after_one_week = week_after_set + 1
    assert_equal(0.0, field.field_daily_weather[emi].pct_cover,field.field_daily_weather[emi-1..emi+10].collect { |fdw| [fdw.date,fdw.pct_cover] }.inspect)
    # Back one day before emergence too
    assert_equal(0.0, field.field_daily_weather[day_before_emergence].pct_cover,field.field_daily_weather[day_before_emergence..emi + 10].collect { |fdw| [fdw.date,fdw.pct_cover] }.inspect)
    field.field_daily_weather[index_to_set].entered_pct_cover = 9.0
    field.field_daily_weather[index_to_set].save!
    field.pct_cover_changed(field.field_daily_weather[index_to_set])
    field.save!
    field = Field.find(field[:id])
    # Very first day of fdw, way back before emergence, certainly shouldn't be affected
    assert_in_delta(0.0, field.field_daily_weather[0].pct_cover, 0.00001,(field.field_daily_weather[0..10].collect { |fdw| [fdw.date,fdw.pct_cover] }.inspect) + " emergence date of #{field.current_crop.emergence_date}")
    # Nor should the day before emergence
    assert_in_delta(0.0, field.field_daily_weather[day_before_emergence].pct_cover, 0.00001,(field.field_daily_weather[day_before_emergence..emi + 10].collect { |fdw| [fdw.date,fdw.pct_cover] }.inspect) + " emergence date of #{field.current_crop.emergence_date}")
    # Emergence day itself should be zero too
    assert_in_delta(0.0, field.field_daily_weather[emi].pct_cover, 0.00001,(field.field_daily_weather[day_before_emergence..emi + 10].collect { |fdw| [fdw.date,fdw.pct_cover] }.inspect) + " emergence date of #{field.current_crop.emergence_date}")
    # Day after emergence should be affected -- halfway between 0 and 9
    assert_in_delta((9.0 - 0.0) / 2.0, field.field_daily_weather[day_after_emergence].pct_cover, 0.00001,(field.field_daily_weather[day_before_emergence..emi + 10].collect { |fdw| [fdw.date,fdw.pct_cover] }.inspect) + " emergence date of #{field.current_crop.emergence_date}")
    # And of course the one we explicitly set s/b unchanged
    assert_in_delta(9.0, field.field_daily_weather[index_to_set].pct_cover, 0.00001,field.field_daily_weather[day_before_emergence..emi + 10].collect { |fdw| [fdw.date,fdw.pct_cover] }.inspect)
    # And we're not haring off further than a week into the future, either, are we laddie
    assert_in_delta(9.0, field.field_daily_weather[week_after_set].pct_cover, 0.00001,field.field_daily_weather[day_before_emergence..emi + 10].collect { |fdw| [fdw.date,fdw.pct_cover] }.inspect)
    assert_in_delta(0.0, field.field_daily_weather[one_day_after_one_week].pct_cover, 0.00001,field.field_daily_weather[day_before_emergence..emi + 10].collect { |fdw| [fdw.date,fdw.pct_cover] }.inspect)
  end
  
  def field_with_soil_type
    Field.all.select {|field| field.soil_type }.first
  end
  
  test "I can find a field with a soil type" do
     assert(field_with_soil_type)
  end
  
  test "remove_incoming_if_default: fc gets pulled when == to default" do
    field = field_with_soil_type
    assert(default_fc = field.soil_type.field_capacity)
    assert(default_pwp = field.soil_type.perm_wilting_pt)
    attribs = {:field_capacity => default_fc.to_s, :perm_wilting_pt => default_pwp.to_s}
    field.remove_incoming_if_default(field.soil_type,attribs,:field_capacity)
    assert_equal(attribs, {:perm_wilting_pt => default_pwp.to_s},attribs.inspect)
  end
  
  test "remove_incoming_if_default: pwp gets pulled when == to default" do
    field = field_with_soil_type
    assert(default_fc = field.soil_type.field_capacity)
    assert(default_pwp = field.soil_type.perm_wilting_pt)
    attribs = {:field_capacity => default_fc.to_s, :perm_wilting_pt => default_pwp.to_s}
    field.remove_incoming_if_default(field.soil_type,attribs,:perm_wilting_pt)
    assert_equal({:field_capacity => default_fc.to_s}, attribs,attribs.inspect)
  end
  
  test "riid: fc left alone when != to default" do
    field = field_with_soil_type
    assert(fc = field.soil_type.field_capacity + 10.0)
    assert(default_pwp = field.soil_type.perm_wilting_pt)
    attribs = {:field_capacity => fc.to_s, :perm_wilting_pt => default_pwp.to_s}
    expected_attribs = {:field_capacity => fc.to_s, :perm_wilting_pt => default_pwp.to_s}
    field.remove_incoming_if_default(field.soil_type,attribs,:field_capacity)
    assert_equal(expected_attribs, attribs, attribs.inspect)
    # and taking the other out still leaves non-default alone
    field.remove_incoming_if_default(field.soil_type,attribs,:perm_wilting_pt)
    assert_equal({:field_capacity => fc.to_s}, attribs)
  end
  
  test "riid: pwp left alone when != to default" do
    field = field_with_soil_type
    assert(default_fc = field.soil_type.field_capacity)
    assert(pwp = field.soil_type.perm_wilting_pt + 10.0)
    attribs = {:field_capacity => default_fc.to_s, :perm_wilting_pt => pwp.to_s}
    expected_attribs = {:field_capacity => default_fc.to_s, :perm_wilting_pt => pwp.to_s}
    field.remove_incoming_if_default(field.soil_type,attribs,:perm_wilting_pt)
    assert_equal(expected_attribs, attribs, attribs.inspect)
    # and, as above, we can yank field capacity and it won't pull pwp
    field.remove_incoming_if_default(field.soil_type,attribs,:field_capacity)
    assert_equal({:perm_wilting_pt => pwp.to_s}, attribs)
  end
  
  test "riid when both are different from default" do
    field = field_with_soil_type
    assert(fc = field.soil_type.field_capacity + 10.0)
    assert(pwp = field.soil_type.perm_wilting_pt + 10.0)
    attribs = {:field_capacity => fc.to_s, :perm_wilting_pt => pwp.to_s}
    expected_attribs = {:field_capacity => fc.to_s, :perm_wilting_pt => pwp.to_s}
    field.remove_incoming_if_default(field.soil_type,attribs,:field_capacity)
    assert_equal(expected_attribs, attribs, attribs.inspect)
    field.remove_incoming_if_default(field.soil_type,attribs,:perm_wilting_pt)
    assert_equal(expected_attribs, attribs, attribs.inspect)
  end
  
  test "groom_for_defaults: no changes, fc and pwp absent in existing record" do
    assert(field = Field.create(:name => 'Test Field',:pivot_id => Pivot.first, :soil_type_id => SoilType.default_soil_type[:id]),"Could not create a field")
    default_fc = field.soil_type.field_capacity
    default_pwp = field.soil_type.perm_wilting_pt
    assert_nil(field[:field_capacity])
    assert_nil(field[:perm_wilting_pt])
    incoming_attributes = {
      :soil_type_id => field.soil_type[:id].to_s,
      :field_capacity => field.field_capacity.to_s,
      :perm_wilting_pt => field.perm_wilting_pt.to_s
    }
    field.groom_for_defaults(incoming_attributes)
    assert_equal({}, incoming_attributes)
  end
  
  test "groom_for_defaults: soil type changed, no other attribs supplied (existing record had nil fc/pwp)" do
    nondefault_soil = SoilType.find(:first, :conditions => ['id != ?',SoilType.default_soil_type[:id]])
    assert(field = Field.create(:name => 'Test Field',:pivot_id => Pivot.first, :soil_type_id => SoilType.default_soil_type[:id]),"Could not create a field")
    default_fc = field.soil_type.field_capacity
    default_pwp = field.soil_type.perm_wilting_pt
    incoming_attributes = {:soil_type_id => nondefault_soil[:id]}
    expected_attributes = {:soil_type_id => nondefault_soil[:id]}
    field.groom_for_defaults(incoming_attributes)
    assert_equal(expected_attributes, incoming_attributes)
    assert_nil(field[:field_capacity])
    assert_nil(field[:perm_wilting_pt])
  end
  
  test "groom_for_defaults: soil type changed, pwp and fc supplied but == to new defaults (existing record had nil fc/pwp)" do
    nondefault_soil = SoilType.find(:first, :conditions => ['id != ?',SoilType.default_soil_type[:id]])
    assert(field = Field.create(:name => 'Test Field',:pivot_id => Pivot.first, :soil_type_id => SoilType.default_soil_type[:id]),"Could not create a field")
    default_fc = field.soil_type.field_capacity
    default_pwp = field.soil_type.perm_wilting_pt
    incoming_attributes = {
      :soil_type_id => nondefault_soil[:id],
      :field_capacity => nondefault_soil.field_capacity,
      :perm_wilting_pt => nondefault_soil.perm_wilting_pt
    }
    expected_attributes = {:soil_type_id => nondefault_soil[:id]}
    field.groom_for_defaults(incoming_attributes)
    assert_equal(expected_attributes, incoming_attributes)
    assert_nil(field[:field_capacity])
    assert_nil(field[:perm_wilting_pt])
  end
  
  test "groom_for_defaults: soil type changed, pwp and fc supplied == to new defaults (existing record had fc/pwp)" do
    nondefault_soil = SoilType.find(:first, :conditions => ['id != ?',SoilType.default_soil_type[:id]])
    assert(
      field = Field.create(
        :name => 'Test Field',
        :pivot_id => Pivot.first,
        :soil_type_id => SoilType.default_soil_type[:id],
        :field_capacity => 0.001,
        :perm_wilting_pt => 0.002
      ),
      "Could not create a field")
    incoming_attributes = {
      :soil_type_id => nondefault_soil[:id].to_s,
      :field_capacity => nondefault_soil.field_capacity.to_s,
      :perm_wilting_pt => nondefault_soil.perm_wilting_pt.to_s
    }
    expected_attributes = {:soil_type_id => nondefault_soil[:id].to_s}
    field.groom_for_defaults(incoming_attributes)
    assert_equal(expected_attributes, incoming_attributes)
    # Even though the field previously had an FC and a PWP, they should now be wiped out so that the new soil's defaults take over
    assert_nil(field[:field_capacity])
    assert_nil(field[:perm_wilting_pt])
  end
  
  test "groom_for_defaults: soil type changed, pwp and fc supplied != to new defaults (existing record had fc/pwp)" do
    nondefault_soil = SoilType.find(:first, :conditions => ['id != ?',SoilType.default_soil_type[:id]])
    assert(
      field = Field.create(
        :name => 'Test Field',
        :pivot_id => Pivot.first,
        :soil_type_id => SoilType.default_soil_type[:id],
        :field_capacity => 0.001,
        :perm_wilting_pt => 0.002
      ),
      "Could not create a field")
    incoming_attributes = {
      :soil_type_id => nondefault_soil[:id].to_s,
      :field_capacity => (nondefault_soil.field_capacity+0.4).to_s,
      :perm_wilting_pt => (nondefault_soil.perm_wilting_pt+0.1).to_s
    }
    # same thing. Yes, it's duplication. Sue me.
    expected_attributes = {
      :soil_type_id => nondefault_soil[:id].to_s,
      :field_capacity => (nondefault_soil.field_capacity+0.4).to_s,
      :perm_wilting_pt => (nondefault_soil.perm_wilting_pt+0.1).to_s
    }
    field.groom_for_defaults(incoming_attributes)
    assert_equal(expected_attributes, incoming_attributes)
    # Even though the field previously had an FC and a PWP, they should now be wiped out (doesn't matter, they'll get overridden, but still.)
    assert_nil(field[:field_capacity])
    assert_nil(field[:perm_wilting_pt])
  end
  
  
  test "groom_for_defaults: soil type UNchanged, pwp and fc supplied == to old defaults (existing record had fc/pwp)" do
    default_soil_id = SoilType.default_soil_type[:id]
    assert(
      field = Field.create(
        :name => 'Test Field',
        :pivot_id => Pivot.first,
        :soil_type_id => default_soil_id,
        :field_capacity => 0.001,
        :perm_wilting_pt => 0.002
      ),
      "Could not create a field")
    incoming_attributes = {
      :soil_type_id => default_soil_id.to_s,
      :field_capacity => 0.4.to_s,
      :perm_wilting_pt => 0.1.to_s
    }
    expected_attributes = {
      :field_capacity => 0.4.to_s,
      :perm_wilting_pt => 0.1.to_s
    }
    field.groom_for_defaults(incoming_attributes)
    assert_equal(expected_attributes, incoming_attributes)
    assert_equal(0.001, field.field_capacity)
    assert_equal(0.002, field.perm_wilting_pt)
    assert_equal(0.001, field[:field_capacity])
    assert_equal(0.002, field[:perm_wilting_pt])
  end
  
  test "field_capacity_pct works" do
    field = create_a_field
    crop = field.current_crop
    assert(crop.emergence_date > field.field_daily_weather[0].date,"Crop (#{crop.name},#{crop[:id]}) emergence date is before FDW starts")
    assert(crop.emergence_date < field.field_daily_weather[-1].date,"Crop (#{crop.name},#{crop[:id]}) emergence date is after FDW ends")
    assert(field.field_daily_weather.size > field.fdw_index(crop.emergence_date),"Field  (#{field.name},#{field[:id]}) only has #{field.field_daily_weather.size} FDWs!")
    field_id = field[:id]
    assert(fc = field.field_capacity)
    assert_equal(fc * 100.0, field.field_capacity_pct)
    field.field_capacity_pct = 20.0
    field.save!
    field_found = Field.find(field_id)
    field.field_capacity = 10.0
    assert_equal(0.2, field_found.field_capacity)
  end
  
  test "perm_wilting_pt_pct works" do
    assert(field = create_a_field, "No field")
    field_id = field[:id]
    assert(pwp = field.perm_wilting_pt, "No PWP")
    assert_not_equal(20.0, pwp)
    assert_equal(pwp * 100.0, field.perm_wilting_pt_pct)
    field.perm_wilting_pt_pct = 20.0
    field.save!
    field_found = Field.find(field_id)
    assert_equal(0.2, field_found.perm_wilting_pt)
    assert_equal(20.0, field_found.perm_wilting_pt_pct)
  end
  
  test "problem on OK field with no target" do
    assert(field = setup_field_with_emergence.first)
    assert_nil(field.target_ad_in)
    assert(field.field_daily_weather.first.ref_et)
    first_date = field.field_daily_weather.first.date
    second_date = first_date + 7
    (0..7).each { |ii| field.field_daily_weather[ii].ad = 1.8 }
    assert_nil(field.problem(first_date,second_date))
  end
  
  test "problem on OK field with target" do
    assert(field = setup_field_with_emergence.first)
    field.target_ad_pct = 0.5
    assert(field.field_daily_weather.first.ref_et)
    first_date = field.field_daily_weather.first.date
    second_date = first_date + 7
    (0..7).each { |ii| field.field_daily_weather[ii].ad = 1.8 }
    assert_nil(field.problem(first_date,second_date))
  end
  
  test "problem on field going negative in non-projected data with no target" do
    assert(field = setup_field_with_emergence.first)
    assert(field.field_daily_weather.first.ref_et)
    first_date = field.field_daily_weather.first.date
    second_date = first_date + 7
    ad_value = 1.0
    (0..7).each do |ii|
      field.field_daily_weather[ii].ad = ad_value
      ad_value -= 0.3
    end
    assert(problem = field.problem(first_date,second_date))
    assert_equal(Hash,problem.class)
    fld = problem.keys.first
    assert_equal(Field, fld.class)
    assert_equal(Array, problem[fld].class)
    assert_equal(Date, problem[fld][0].class)
    assert_equal(Float,problem[fld][1].class)
  end

  test "problem on field going negative in non-projected data with target" do
    assert(field = setup_field_with_emergence.first)
    assert(field.field_daily_weather.first.ref_et)
    first_date = field.field_daily_weather.first.date
    second_date = first_date + 7
    ad_value = 1.0
    field.target_ad_pct = 0.5
    (0..7).each do |ii|
      field.field_daily_weather[ii].ad = ad_value
      ad_value -= 0.3
    end
    assert(problem = field.problem(first_date,second_date))
    assert_equal(Hash, problem.class,"Problem looks more like: #{problem.inspect}")
  end
  
  test "do_balances" do
    field,emergence_date = setup_pct_cover_field_with_emergence
    field.do_balances
    field.do_balances(field.current_crop.emergence_date + 5)
  end
  
  test "changes to crop affect field ad_max" do
    field,emergence_data = setup_pct_cover_field_with_emergence
    assert_difference "field.ad_max", field.ad_max do # Should double, since the MRZD is doubling
      field.current_crop.max_root_zone_depth *= 2.0
      field.current_crop.save!
    end
  end

  test "changes to crop affect FDW ad" do
    field,emergence_data = setup_pct_cover_field_with_emergence
    emi = field.fdw_index(field.current_crop.emergence_date)
    assert_difference "field.field_daily_weather[emi].ad", field.ad_max do # Should double, since the MRZD is doubling
      field.current_crop.max_root_zone_depth *= 2.0
      field.current_crop.save!
      field.field_daily_weather.reload
    end
  end
  
  # Projected-AD stuff
  test "can call mad_adj_et_in_past_week" do
    field,emergence_data = setup_pct_cover_field_with_emergence
    (31..40).each { |ii| field.field_daily_weather[ii].ref_et = (0.2 - ii.to_f / 1000.0); field.field_daily_weather[ii].entered_pct_cover = ii.to_f }
    field.field_daily_weather[35].ref_et = 0.4
    field.save!
    field = Field.find(field[:id])
    assert(max_adj_et = field.max_adj_et_in_past_week(37), "Could not call and get a result")
    assert_in_delta(0.240238, max_adj_et, 2 ** -20)
  end
  
<<<<<<< .working
  test "getting problem ad" do
    field = Field.create(name: 'Problem field', pivot_id: Pivot.first[:id])
    ed = field.current_crop.emergence_date
    #Set up field daily weather with two AD zero crossings to negative 
    field.field_daily_weather.each_with_index { |data, ii|
      data.ref_et = 0.17
      if data.date > ed && ii < 100 
        data.entered_pct_cover = ii
      end
      if ii == 110
        data.rain = 7.0
      end
    }
    field.save!
    field.do_balances
    field.field_daily_weather.reload
    fdw = FieldDailyWeather.fdw_for(field[:id],ed,ed+90)
    
    ## Testing the test
    # last_ad = 999.0
    # crossing_count = 0
    # fdw.each do |data|
      ##puts (data.date.to_s + " " + data.entered_pct_cover.to_s + " " + data.ad.to_s)
      # if (last_ad >= 0 && data.ad < 0)
        # puts ("Zero crossing on " + data.date.to_s ) # Should find crossings on 2011-06-21 and 2011-07-29
        # crossing_count += 1;
      # end
      # last_ad = data.ad
    # end
    # assert_equal(crossing_count,2,"Wrong number of AD zero crossings")

    # Test for problem today
    problems = field.problem(Date.new(2011,06,21))
    assert_not_nil(problems,"Did not find AD problem on test date")
    assert_equal(Date.new(2011,06,21),problems[problems.keys[0]][0],"AD problem wrong date: test date #{problems[problems.keys[0]][0]}")
    
    # Test for problem tomorrow
    problems = field.problem(Date.new(2011,06,20))
    assert_not_nil(problems,"Did not find AD problem on test date + 1")
    assert_equal(Date.new(2011,06,21),problems[problems.keys[0]][0],"AD problem wrong date: test date + 1 #{problems[problems.keys[0]][0]}")

    # Test for problem in two days
    problems = field.problem(Date.new(2011,06,19))
    assert_not_nil(problems,"Did not find AD problem on test date + 2")
    assert_equal(Date.new(2011,06,21),problems[problems.keys[0]][0],"AD problem wrong date: test date + 2 #{problems[problems.keys[0]][0]}")
    
  end
  
  test "get_dds works" do
    field,emergence_data = setup_pct_cover_field_with_emergence
    field.pivot.latitude = 44.12
    field.pivot.longitude = -89.3
    field.pivot.save!
    field.get_dds
    date = field.field_daily_weather[100].date
    fdw = FieldDailyWeather.where(field_id: field.id).where(date: date).first
    assert(fdw)
    assert(fdw.degree_days)
    assert(fdw.degree_days > 0,fdw.inspect)
  end

  test "RingBuffer works with default" do
    rb = nil
    assert_nothing_raised(RuntimeError) { rb = RingBuffer.new }
    assert(rb, "RingBuffer not returned")
    # Should be zero when empty
    assert_nil(rb.mean)
    rb.add(-1.0)
    assert_in_delta(-1.0, rb.mean, 2 ** -20)
    rb.add(1.0)
    assert_in_delta(0.0, rb.mean, 2 ** -20)
    rb = RingBuffer.new
    # Fill it
    vals = [0.0,1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0]
    sum = vals.inject(0.0) { |int_sum, val| int_sum + val }
    val_mean = sum / vals.size
    vals.each { |val| rb.add(val) }
    assert(mean = rb.mean,"Mean returned nil for #{rb.inspect}")
    assert_in_delta(val_mean, rb.mean, 2 ** -20)
    # Adding a number should overwrite the zero; sum should be 56, mean 5.6
    rb.add(11.0)
    assert_in_delta(5.6, rb.mean, 2 ** -20)
  end
  
  test "RingBuffer works with smaller value" do
    rb = RingBuffer.new(5)
    assert_nil(rb.mean)
    # Stuff in six values, first s/b dropped, so vals should end up 1 2 3 4 5 for a 15 sum and 3.0 mean
    6.times {|ii| rb.add(ii.to_f)}
    assert_in_delta(3.0, rb.mean, 2 ** -20,rb.dump.inspect)
  end

  test "RingBuffer max works" do
    rb = RingBuffer.new(3)
    5.times { |ii| rb.add(ii.to_f) } # Should end up with [3,4,2]
    assert_equal(4.0, rb.max)
  end
  
  test "RingBuffer big_enough works" do
    {0.1 => true, -0.1 => true, 0.0 => false, 0.00001 => true, -0.00001 => true, 0.000000000001 => false, -0.0000000000001 => false}.each do |val,expected|
      assert_equal(expected, RingBuffer.big_enough(val))
    end
  end
  
  test "RingBuffer ignore_zeros works" do
    rb = RingBuffer.new(12)
    5.times { |ii| rb.add(ii.to_f) } # [0,1,2,3,4]
    rb.add(0.0) # Put a zero in the middle, to flush out ordering effects
    10.downto(7) {|ii| rb.add(ii.to_f) } # [0,1,2,3,4,0,10,9,8,7]
    # Sum is 44, counting ten values should get a mean of 4.4
    assert_in_delta(4.4, rb.mean, 2 ** -20)
    # But throwing out the zero values, should be 44 / 8 = 5.5
    assert_in_delta(5.5, rb.mean(true), 2 ** -20)
  end
  
  test "RingBuffer ignore_zeros returns nil when called on an all-zero buffer" do
    rb = RingBuffer.new(3)
    assert_nil(rb.mean(true),'Should return nil when called on empty buffer with ignore_zeros flag')
    3.times { rb.add(0.0)}
    assert_nil(rb.mean(true),'Should return nil when called on buffer full of zeros with ignore_zeros flag')
  end
  
  test "RingBuffer last_nonzero works" do
    rb = RingBuffer.new(6)
    assert_nil(rb.last_nonzero,'last_nonzero should return nil on empty buffer')
    [0.0,0.0].each { |val| rb.add(val) }
    assert_nil(rb.last_nonzero,'last_nonzero should return nil on buffer with nothing but zeros')
    rb.add(1.0)
    assert_in_delta(1.0, rb.last_nonzero, 2 ** -20)
    rb.add(0.0)
    assert_in_delta(1.0, rb.last_nonzero, 2 ** -20)
    rb.add(2.0)
    assert_in_delta(2.0, rb.last_nonzero, 2 ** -20)
    rb.add(-4.0)
    assert_in_delta(-4.0, rb.last_nonzero, 2 ** -20)    
  end
end
