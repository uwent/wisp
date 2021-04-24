FactoryBot.define do
  factory :field do
    association :pivot, strategy: :build
    association :soil_type, strategy: :build
  end
end
