require 'rails_helper'

describe WeatherStation do
  let(:weather_station) { create(:weather_station) }
  let(:year) { Time.now.year }
  let(:starts_on) { Field.starts_on(year) }
  let(:ends_on) { Field.ends_on(year) }
  let(:days) { ends_on - starts_on + 1 }

  describe '#ensure_data_for' do
    before do
      allow_any_instance_of(Field)
        .to receive(:date_endpoints)
        .and_return([Date.yesterday, Date.today])
    end

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
            expect { weather_station_data.update(rain: 4.0) }.to change { field_daily_weather.reload.rain }.to(4.0)
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
            expect { weather_station_data.update(entered_pct_cover: new_entered_pct_cover) }.to change { field_daily_weather.reload.entered_pct_cover }.to(new_entered_pct_cover)
          end
        end
      end
    end

    describe '#new_year' do
      it 'should remove weather_station_data' do
        weather_station.reload
        weather_station.weather_station_data << create(:weather_station_data, date: Date.yesterday)
        weather_station.weather_station_data do |wsd|
          expect(wsd).to receive(:destroy!)
        end
        weather_station.new_year
        expect(weather_station.weather_station_data).to be_empty
      end
    end

    describe '#destroy' do
      before do
        allow_any_instance_of(Field)
          .to receive(:date_endpoints)
          .and_return([Date.yesterday, Date.today])
      end

      it 'should remove weather_station_data' do
        weather_station.reload
        weather_station.weather_station_data << create(:weather_station_data, date: Date.yesterday)
        expect { weather_station.destroy }.to change { WeatherStationData.count }
      end
    end
  end
end
