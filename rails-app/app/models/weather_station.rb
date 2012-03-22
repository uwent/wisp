class WeatherStation < ActiveRecord::Base
  belongs_to :group
  belongs_to :pivot
  has_many :weather_station_data
end
