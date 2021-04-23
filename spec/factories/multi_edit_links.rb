FactoryBot.define do
  factory :multi_edit_link do
    association :field, strategy: :build
    association :weather_station, strategy: :build
  end
end
