class WeatherStation < ActiveRecord::Base
  belongs_to :group
  has_many :weather_station_data
end
