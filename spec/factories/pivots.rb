FactoryGirl.define do
  factory :pivot do
    association :farm, strategy: :build
  end
end
