class AddIndexToWeatherStationDataForDate < ActiveRecord::Migration
  def change
    change_column :weather_station_data, :weather_station_id, :integer, null: false
    change_column :weather_station_data, :date, :date, null: false

    def for_logging(record)
      record.attributes.map do |key, value|
        "#{key}: #{value}"
      end.join("\n")
    end

    WeatherStationData
      .select([:weather_station_id, :date])
      .group(:weather_station_id, :date)
      .having('count(*) > 1')
      .each do |weather_station_data_key|

      uniques = WeatherStationData
        .where(weather_station_data_key.attributes)
        .map do |weather_station_data|
        weather_station_data
          .attributes
          .except('id', 'created_at', 'updated_at')
      end
        .uniq

      newest = WeatherStationData
        .where(weather_station_data_key.attributes)
        .order(:updated_at)
        .last

      others = WeatherStationData
        .where(weather_station_data_key.attributes)
        .where('id <> ?', newest.id)

      if uniques.count == 1
        others.delete_all
      else
        keeping = for_logging(newest)
        deleting = others.map do |record|
          for_logging(record)
        end.join("\n")

        Rails.logger.warn("Not unique: #{weather_station_data_key.attributes}")
        Rails.logger.warn("Keeping: #{keeping}")
        Rails.logger.warn("Deleting: #{deleting}")

        others.delete_all
      end
    end

    add_index :weather_station_data, [:weather_station_id, :date], unique: true
  end
end
