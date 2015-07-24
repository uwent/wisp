require 'rails_helper'

describe WeatherStation do
  let(:weather_station) { create(:weather_station) }
  let(:year) { Time.now.year }
  let(:starts_on) { Field.starts_on(year) }
  let(:ends_on) { Field.ends_on(year) }
  let(:days) { ends_on - starts_on + 1 }

  describe '#ensure_data_for' do
    context 'when weather station data exists for the start date' do
      before { create(:weather_station_data, weather_station: weather_station, date: starts_on) }

      context 'and weather station data exists for the end date' do
        before { create(:weather_station_data, weather_station: weather_station, date: ends_on) }

        it 'does not create new weather station data' do
          expect { weather_station.ensure_data_for(year) }.not_to change { WeatherStationData.count }
        end
      end

      context 'but weather station data does not exist for the end date' do
        it 'creates new weather station data for the missing dates' do
          expect { weather_station.ensure_data_for(year) }.to change { WeatherStationData.count }.by(days - 1)
        end
      end
    end

    context 'when weather station data does not exist for the start date' do
      context 'but weather station data exists for the end date' do
        before { create(:weather_station_data, weather_station: weather_station, date: ends_on) }

        it 'creates new weather station data for the missing dates' do
          expect { weather_station.ensure_data_for(year) }.to change { WeatherStationData.count }.by(days - 1)
        end
      end

      context 'and weather station data does not exist for the end date' do
        it 'creates new weather station data for the missing dates' do
          expect { weather_station.ensure_data_for(year) }.to change { WeatherStationData.count }.by(days)
        end
      end
    end
  end

  describe '#wx_record_saved' do
    context 'when there is a weather station' do
      let(:multi_edit_link) { create :multi_edit_link }
      let(:weather_station) { multi_edit_link.weather_station }
      let(:field) { multi_edit_link.field }

      context 'and it has weather station data for the current year' do
        before { weather_station.ensure_data_for(year) }

        let(:weather_station_data) { weather_station.weather_station_data.for_date(starts_on).first }
        let(:field_daily_weather) { field.field_daily_weather.where(date: starts_on).first }

        context 'when weather station data is changed' do
          it 'updates the field daily weather' do
            expect { weather_station_data.update_attributes(rain: 4.0) }.to change { field_daily_weather.reload.rain }.to(4.0)
          end
        end

        context 'when the weather station data includes percent cover' do
          let(:pct_cover) { 3.0 }
          let(:new_entered_pct_cover) { 5.0 }

          before do
            field_daily_weather.entered_pct_cover = pct_cover
            field_daily_weather.save!
          end

          it 'propagates to field daily weather' do
            expect { weather_station_data.update_attributes(entered_pct_cover: new_entered_pct_cover) }.to change { field_daily_weather.reload.entered_pct_cover }.to(new_entered_pct_cover)
          end
        end
      end
    end
  end
end
#
# class WeatherStationTest < ActiveSupport::TestCase
#
#   def lai_to_stuff(day,ending_value,n_days)
#     return 0.0 unless ending_value
#     return ending_value * (day / n_days)
#   end
#
#   def extend_fdw_backwards(field)
#     unless (size_delta = FieldDailyWeather::SEASON_DAYS - field.field_daily_weather.size) == 0
#       puts "extend_fdw_backwards: size_delta is #{size_delta}"
#       first_fdw = field.field_daily_weather.first
#       date = first_fdw.date - 30
#       assert_equal("#{date.year.to_s}-04-01", date.to_s)
#       size_delta.times do |ii|
#         fdw = FieldDailyWeather.create(:field_id => field[:id], :date => date,
#           :leaf_area_index => lai_to_stuff(ii,first_fdw[:leaf_area_index],size_delta))
#       end
#     end
#   end
#
#   def setup
#     @farm = farms(:ricks_farm)
#     @pivot = pivots(:pivot_2012)
#     @year = @pivot.cropping_year
#     assert_equal(@farm, @pivot.farm)
#     @field = @pivot.fields.first
#     extend_fdw_backwards(@field)
#     @field.field_daily_weather.reload
#     assert_equal(FieldDailyWeather::SEASON_DAYS, @field.field_daily_weather.size)
#     first_fdw = @field.field_daily_weather.first
#     assert_equal("#{first_fdw.date.year.to_s}-04-01",first_fdw.date.to_s)
#     @station = weather_stations(:wx_stn_2012)
#     @station.ensure_data_for(@year)
#     @multi_field_test = true # Takes a hella long time
#   end
#
#   test "setup works" do
#     assert(@farm && @year && @pivot && @field && @station && @field.field_daily_weather.size > 0 && @station.weather_station_data.size > 0)
#     assert @field.et_method
#   end
#
#   test "can build weather" do
#     WeatherStationData.destroy_all
#     assert(station = WeatherStation.first, "No weather stations")
#     unless station.pivot
#       assert(pivot = Pivot.first, "No pivots")
#       station.pivot = pivot
#       station.save!
#     end
#     assert_equal(0, station.weather_station_data.size)
#     station.ensure_data_for(Time.now.year)
#     assert_equal(FieldDailyWeather::SEASON_DAYS, station.weather_station_data.size)
#   end
#
#   test "can overwrite nil data in fdw" do
#     assert_equal(FieldDailyWeather::SEASON_DAYS, @field.field_daily_weather.size)
#
#     assert(fdw = wx_for(@field.field_daily_weather,'2012-08-24'))
#     assert_equal('2012-08-24', fdw.date.to_s)
#     updated = fdw.updated_at
#     assert_equal(0.0,fdw.rain)
#     assert(wsd = wx_for(@station.weather_station_data,'2012-08-24'))
#     assert_equal('2012-08-24', wsd.date.to_s)
#     wsd.update_attributes({:rain => 4.0})
#     @field.field_daily_weather.reload
#     assert(fdw = wx_for(@field.field_daily_weather,'2012-08-24'))
#     assert_equal('2012-08-24', fdw.date.to_s)
#     assert(fdw.updated_at > updated, "Should have changed the Aug 24 FDW record")
#     assert_equal(4.0, fdw.rain)
#   end
#
#   test "can overwrite non-nil data in fdw" do
#     assert(fdw = wx_for(@field.field_daily_weather,'2012-08-24'))
#     fdw.update_attributes({:rain => 5.0})
#     @field.field_daily_weather.reload
#     assert(fdw = wx_for(@field.field_daily_weather,'2012-08-24'))
#     updated = fdw.updated_at
#     assert_equal(5.0,fdw.rain)
#     assert(wsd = wx_for(@station.weather_station_data,'2012-08-24'))
#     wsd.update_attributes({:rain => 4.0})
#     @field.field_daily_weather.reload
#     assert(fdw = wx_for(@field.field_daily_weather,'2012-08-24'))
#     assert(fdw.updated_at > updated, "Should have changed the Aug 24 FDW record")
#     assert_equal(4.0, fdw.rain)
#   end
#
#   test "can update all attributes" do
#     wx_attribs_to_set = {:rain => 4.0, :irrigation => 2.0, :ref_et => 0.2, :entered_pct_moisture => 0.33}
#     fdw_attribs_to_check = {:rain => 0.0, :irrigation => 0.0, :ref_et => 0.15, :pct_moisture => nil}
#     assert(fdw = wx_for(@field.field_daily_weather,'2012-08-24'))
#     fdw_attribs_to_check.each { |col,val| assert_equal(fdw_attribs_to_check[col], fdw.send(col.to_s),"attrib #{col.to_s}") }
#     assert(wsd = wx_for(@station.weather_station_data,'2012-08-24'))
#     wsd.update_attributes(wx_attribs_to_set)
#     @field.field_daily_weather.reload
#     assert(fdw = wx_for(@field.field_daily_weather,'2012-08-24'))
#     wx_attribs_to_set.each { |col,val| assert_equal(val, fdw.send(col.to_s),"attrib #{col.to_s}") }
#   end
#
#   test "can update multiple fields" do
#     return unless @multi_field_test
#     wx_attribs_to_set = {:rain => 4.0, :irrigation => 2.0, :ref_et => 0.2, :entered_pct_moisture => 0.33}
#     f2 = Field.create(:pivot => @pivot,:name => 'Test field f2', :field_capacity => 0.15)
#     f3 = Field.create(:pivot => @pivot,:name => 'Test field f3', :field_capacity => 0.15)
#     assert_equal(FieldDailyWeather::SEASON_DAYS,f2.field_daily_weather.size)
#     @pivot.fields.each do |field|
#       fdw = wx_for(field.field_daily_weather,'2012-08-24')
#       wx_attribs_to_set.each { |col,val| assert_not_equal(val, fdw.send(col.to_s),"Unexpectedly, fdw for field #{field.name} was already set") }
#     end
#     assert(wsd = wx_for(@station.weather_station_data,'2012-08-24'))
#     wsd.update_attributes(wx_attribs_to_set)
#     @pivot.fields.reload
#     @pivot.fields.each { |field| field.field_daily_weather.reload }
#     @pivot.fields.each do |field|
#       fdw = wx_for(field.field_daily_weather,'2012-08-24')
#       wx_attribs_to_set.each { |col,val| assert_equal(val, fdw.send(col.to_s),"Unexpectedly, fdw for field #{field.name} was already set") }
#     end
#   end
#
#   test "AD balances get updated" do
#     wx_attribs_to_set = {:rain => 14.0, :irrigation => 2.0, :ref_et => 0.2} #, :entered_pct_moisture => 0.33
#     f2 = Field.create(:pivot => @pivot,:name => 'Test field f2')
#     f3 = Field.create(:pivot => @pivot,:name => 'Test field f3')
#     [f2,f3].each { |f| f.field_daily_weather.each { |fdw| fdw.ref_et = 0.2 }; f.save! }
#     fdw_24 = wx_for(f2.field_daily_weather,'2012-08-24')
#     fdw_25 = wx_for(f2.field_daily_weather,'2012-08-25')
#     assert(wsd = wx_for(@station.weather_station_data,'2012-08-24'))
#     old_moisture = fdw_25.calculated_pct_moisture
#     old_ad = fdw_25.ad
#     wsd.update_attributes(wx_attribs_to_set)
#     f2.field_daily_weather.reload
#     fdw_25 = wx_for(f2.field_daily_weather,'2012-08-25')
#     assert_not_equal(old_moisture, fdw_25.calculated_pct_moisture)
#     assert_not_equal(old_ad, fdw_25.ad)
#   end
#
#   test "entered_pct_cover propagates to field_daily_weather" do
#     DATE_TO_TEST = '2012-08-25'
#     Field.delete_all
#     Crop.delete_all
#     assert(def_plant = Plant.default_plant)
#     assert_equal(Potato, def_plant.class)
#     field = Field.create(:pivot => @pivot, :name => 'Test Field', :et_method => Field::PCT_COVER_METHOD)
#     assert(wsd = wx_for(@station.weather_station_data,DATE_TO_TEST))
#     fdw_25 = wx_for(field.field_daily_weather,DATE_TO_TEST)
#     assert(field.current_crop,"Field has no crop")
#     assert(field.current_crop.plant,"Crop has no plant")
#     assert(field.current_crop.plant.adj_et_pct_cover(fdw_25.ref_et,fdw_25.pct_cover),"Plant couldn't do adj_et")
#     fdw_25.entered_pct_cover = old_pct_cover = 3.0
#     fdw_25.save!
#     wsd.update_attributes({:entered_pct_cover => old_pct_cover + 5.0}) # peturb it by some arbitrary amount
#     field.field_daily_weather.reload
#     fdw_25 = wx_for(field.field_daily_weather,DATE_TO_TEST)
#     assert_not_equal(old_pct_cover,fdw_25.entered_pct_cover)
#   end
#
#   # def set_up_field_for_ad_balance()
#   #   f2 = Field.create(:pivot => @pivot,:name => 'Test field f2')
#   #   f3 = Field.create(:pivot => @pivot,:name => 'Test field f3')
#   #   [f2,f3].each { |f| f.field_daily_weather.each { |fdw| fdw.ref_et = 0.2 }; f.save! }
#   #   fdw_24 = wx_for(f2.field_daily_weather,'2012-08-24')
#   #   fdw_25 = wx_for(f2.field_daily_weather,'2012-08-25')
#   #   assert(wsd = wx_for(@station.weather_station_data,'2012-08-24'))
#   #   assert_in_delta(-14.82, fdw_25.ad, 0.05)
#   #   old_moisture = fdw_25.calculated_pct_moisture
#   #   old_ad = fdw_25.ad
#   #   [f2,wsd,old_moisture,old_ad]
#   # end
#   #
#   # test "AD balances get updated" do
#   #   f2,wsd,old_moisture,old_ad = set_up_field_for_ad_balance
#   #   wx_attribs_to_set = {:rain => 14.0, :irrigation => 2.0, :ref_et => 0.2} #, :entered_pct_moisture => 0.33
#   #   wsd.update_attributes(wx_attribs_to_set)
#   #   f2.field_daily_weather.reload
#   #   fdw_25 = wx_for(f2.field_daily_weather,'2012-08-25')
#   #   assert_not_equal(old_moisture, fdw_25.calculated_pct_moisture)
#   #   assert_not_equal(old_ad, fdw_25.ad)
#   # end
#   #
# end
