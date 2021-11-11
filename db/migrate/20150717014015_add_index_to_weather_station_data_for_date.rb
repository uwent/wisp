class AddIndexToWeatherStationDataForDate < ActiveRecord::Migration[4.2]
  def change
    change_column :weather_station_data, :weather_station_id, :integer, null: false
    change_column :weather_station_data, :date, :date, null: false

    def for_logging(record)
      record.attributes.map do |key, value|
        "#{key}: #{value}"
      end.join("\n")
    end

    duplicates = WeatherStationData
      .select([:weather_station_id, :date])
      .group(:weather_station_id, :date)
      .having("count(*) > 1")

    Rails.logger.info("Number of duplicates: #{duplicates.to_a.size}")

    duplicates.each do |weather_station_data_key|
      weather_station_data_key_attributes = weather_station_data_key.attributes.except("id")

      uniques = WeatherStationData
        .where(weather_station_data_key_attributes)
        .map do |weather_station_data|
        weather_station_data
          .attributes
          .except("id", "created_at", "updated_at")
      end
        .uniq

      newest = WeatherStationData
        .where(weather_station_data_key_attributes)
        .order(:updated_at)
        .last

      others = WeatherStationData
        .where(weather_station_data_key_attributes)
        .where("id <> ?", newest.id)

      if uniques.count == 1
        others.delete_all
      else
        keeping = for_logging(newest)
        deleting_not_empty = others
          .reject(&:empty?)
          .map do |record|
          for_logging(record)
        end

        if deleting_not_empty.any?
          Rails.logger.warn("Duplicate: #{weather_station_data_key_attributes}")
          Rails.logger.warn("Keeping:\n#{keeping}")

          value = deleting_not_empty.join("\n")
          Rails.logger.warn("Deleting but not empty:\n#{value}")
        end

        others.delete_all
      end
    end

    add_index :weather_station_data, [:weather_station_id, :date], unique: true
  end
end
