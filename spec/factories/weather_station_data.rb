FactoryBot.define do
  factory :weather_station_data do
    association :weather_station, strategy: :build
  end
end
