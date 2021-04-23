FactoryBot.define do
  factory :farm do
    association :group, strategy: :build
  end
end
