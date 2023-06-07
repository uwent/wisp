require "test_helper"

class WeatherStationDataControllerTest < ActionController::TestCase
  setup do
    @farm = farms(:ricks_farm)
    @farm.group.users << users(:rick)
    @pivot = pivots(:pivot_2012)
    @year = @pivot.cropping_year
    assert_equal(@farm, @pivot.farm)
    @field = @pivot.fields.first
    @station = weather_stations(:wx_stn_2012)
    @station.ensure_data_for(@year)
    assert(@farm)
    assert(@farm.group)
    assert(@farm.group.users)
    assert(@farm.group.users.first, "Should be users for #{@farm.group.inspect}; #{User.all.inspect}")
  end

  test "post_data on a connected weather station propagates its changes" do
    wx_attribs_to_set = {rain: 4.0, irrigation: 2.0, ref_et: 0.2, entered_pct_moisture: 0.33}
    f2 = Field.create(pivot: @pivot, name: "Test field f2")
    f3 = Field.create(pivot: @pivot, name: "Test field f3")
    assert(wsd = wx_for(@station.weather_station_data, "2012-08-24"))
    post :post_data, wx_attribs_to_set.merge({id: wsd[:id], user_id: @farm.group.users.first[:id]})
    # check_values([@field,f2,f3],@station,wx_attribs_to_set)
    @station.weather_station_data.reload
    assert(wsd = wx_for(@station.weather_station_data, "2012-08-24"))
    wx_attribs_to_set.each { |col, val| assert_in_delta(val, wsd[col], 2**-20) }
    [@field, f2, f3].each { |field| field.field_daily_weather.reload }
    assert(field_wx = wx_for(@field.field_daily_weather, "2012-08-24"), "No fdw for field")
    assert(f2_wx = wx_for(f2.field_daily_weather, "2012-08-24"), "No fdw for f2")
    assert(f3_wx = wx_for(f3.field_daily_weather, "2012-08-24"), "No fdw for f3")
    [field_wx, f2_wx, f3_wx].each do |fdw|
      wx_attribs_to_set.each { |col, val| assert_in_delta(val, fdw[col], 2**-20, "#{fdw.field.name}: #{fdw.inspect}") }
    end
  end

  def enumerate_error(wx_attribs, fdw)
    wx_attribs.keys.collect { |wxcol| "#{wxcol}: #{wx_attribs[wxcol]} / #{fdw[wxcol]}" }.join(",")
  end

  def check_values(fields, station, wx_attribs_to_set, mesg = "")
    station.weather_station_data.reload
    assert(wsd = wx_for(station.weather_station_data, "2012-08-24"))
    wx_attribs_to_set.each { |col, val| assert_in_delta(val, wsd[col], 2**-20) }
    fields.each { |field| field.field_daily_weather.reload }
    fields.collect { |f| wx_for(f.field_daily_weather, "2012-08-24") }.each do |fdw|
      assert(fdw, "No FDW for field" + mesg)
      wx_attribs_to_set.each { |col, val| assert_in_delta(val, fdw[col], 2**-20, "#{fdw.field.name}: #{enumerate_error(wx_attribs_to_set, fdw)} #{mesg}") }
    end
  end

  test "re-entering multiple times rewrites values each time" do
    wx_attribs_to_set = {rain: 4.0, irrigation: 2.0, ref_et: 0.2}
    f2 = Field.create(pivot: @pivot, name: "Test field f2")
    f3 = Field.create(pivot: @pivot, name: "Test field f3")
    assert(wsd = wx_for(@station.weather_station_data, "2012-08-24"))
    post :post_data, wx_attribs_to_set.merge({id: wsd[:id], user_id: @farm.group.users.first[:id]})
    check_values([@field, f2, f3], @station, wx_attribs_to_set, " first set of values")
    wx_attribs_to_set = {rain: 1.0, irrigation: 3.0, ref_et: 0.1}
    post :post_data, wx_attribs_to_set.merge({id: wsd[:id], user_id: @farm.group.users.first[:id]})
    check_values([@field, f2, f3], @station, wx_attribs_to_set, " second set of values")
    wx_attribs_to_set = {rain: 0.0, irrigation: 0.0, ref_et: 0.0}
    post :post_data, wx_attribs_to_set.merge({id: wsd[:id], user_id: @farm.group.users.first[:id]})
    check_values([@field, f2, f3], @station, wx_attribs_to_set, " setting to zero")
    wx_attribs_to_set = {rain: 5.1, irrigation: 4.1, ref_et: 0.21}
    post :post_data, wx_attribs_to_set.merge({id: wsd[:id], user_id: @farm.group.users.first[:id]})
    check_values([@field, f2, f3], @station, wx_attribs_to_set, " last set of values")
  end
end
