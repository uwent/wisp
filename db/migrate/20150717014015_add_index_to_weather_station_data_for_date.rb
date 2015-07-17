class AddIndexToWeatherStationDataForDate < ActiveRecord::Migration
  def change
    change_column :weather_station_data, :weather_station_id, :integer, null: false
    change_column :weather_station_data, :date, :date, null: false

    # TODO: Make the data unique
    # WeatherStationData
    #   .select([:weather_station_id, :date])
    #   .group(:weather_station_id, :date)
    #   .having('count(*) > 1')
    #   .each do |weather_station_data_key|
    #
    #   uniques = WeatherStationData
    #     .where(weather_station_data_key.attributes)
    #     .map do |weather_station_data|
    #     weather_station_data
    #       .attributes
    #       .except('id', 'created_at', 'updated_at')
    #   end
    #     .uniq
    #
    #   if uniques.count > 1
    #     puts "Not unique: #{weather_station_data_key.attributes}"
    #   end
    # end
    #
    # add_index :weather_station_data, [:weather_station_id, :date], unique: true
  end
end
