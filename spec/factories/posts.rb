FactoryBot.define do
  factory :post do
    text { Faker::Lorem.question(word_count: rand(5..10)) }
    author_id { create(:user).id }

    trait :liked do
      transient do
        like_count { 1 }
      end

      after(:create) do |post, evaluator|
        create_list(:post_like, evaluator.like_count, message_id: post.id)
      end
    end

    trait :commented do
      transient do
        comment_count { 1 }
      end

      after(:create) do |post, evaluator|
        create_list(:comment, evaluator.comment_count, post_id: post.id)
      end
    end

    trait :commented_with_replies do
      transient do
        replied_comment_count { 1 }
      end

      after(:create) do |post, evaluator|
        create_list(:comment, evaluator.replied_comment_count, :reply, post_id: post.id)
      end
    end

    trait :reposted do
      transient do
        repost_count { 1 }
      end

      after(:create) do |post, evaluator|
        create_list(:post_repost, evaluator.repost_count, message_id: post.id)
      end
    end
  end
end
