FactoryGirl.define do
  factory :weather_station do
    association :group, strategy: :build
  end
end
