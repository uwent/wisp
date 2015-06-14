class MultiEditLink < ActiveRecord::Base
  belongs_to :field
  belongs_to :weather_station
end
