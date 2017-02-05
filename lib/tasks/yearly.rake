namespace :yearly do
  desc "Remove past years weather data and set pivots to current year"
  task reset: :environment do
    Pivot.find_each do |pivot| 
      Rails.logger.info("Culling Pivot: #{pivot.id}")
      pivot.new_year
    end

    WeatherStation.find_each do |weather_station| 
      weather_station.new_year
      Rails.logger.info("Culling Weather Station: #{weather_station.id}")
    end
  end
end
