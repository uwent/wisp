FactoryBot.define do
  factory :pivot do
    latitude 44.5
    longitude -89.2
    equipment 'Some equipment'
    pump_capacity 1.23
    some_energy_rate_metric 3.45
    notes 'some notes'

    association :farm, strategy: :build
  end
end
