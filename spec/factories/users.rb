FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    sequence(:display_name) { |n| "User #{n}" }
    sequence(:email) { |n| "email#{n}@somewhere.com" }

    password { "s0cRa+35" }

    trait :confirmed do
      confirmed_at { Time.current }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :with_followers do
      transient do
        follower_count { 1 }
      end

      after(:create) do |user, evaluator|
        create_list(:follow, evaluator.follower_count, followee_id: user.id)
      end
    end

    trait :with_followed_users do
      transient do
        followed_user_count { 1 }
      end

      after(:create) do |user, evaluator|
        create_list(:follow, evaluator.followed_user_count, follower_id: user.id)
      end
    end
  end
end
