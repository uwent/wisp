FactoryBot.define do
  factory :user do
    first_name { "Mark" }
    last_name { "McEahern" }
    email { "mark@mceahern.com" }
    password { "password" }
    confirmed_at { Time.now }
  end
end
