FactoryBot.define do
  factory :post do
    text { Faker::Lorem.question(word_count: rand(5..10)) }
    author_id { create(:user).id }

    trait :commented do
      transient do
        comment_count { 1 }
      end

      after(:create) do |post, evaluator|
        create_list(:comment, evaluator.comment_count, post_id: post.id)
      end
    end
  end
end
