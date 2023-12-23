FactoryBot.define do
  factory :author do
    sequence(:username) { |n| "user#{n}" }
    sequence(:email) { |n| "email#{n}@somewhere.com" }
  end
end
