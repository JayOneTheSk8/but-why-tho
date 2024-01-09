FactoryBot.define do
  factory :comment do
    text { Faker::Lorem.question(word_count: rand(5..10)) }
    author_id { create(:user).id }
    post_id { create(:post).id }

    trait :reply do
      transient do
        comment { create(:comment, post_id:) }
      end

      parent_id { comment.id }
    end

    trait :liked do
      transient do
        like_count { 1 }
      end

      after(:create) do |comment, evaluator|
        create_list(:comment_like, evaluator.like_count, message_id: comment.id)
      end
    end

    trait :replied do
      transient do
        reply_count { 1 }
      end

      after(:create) do |comment, evaluator|
        create_list(
          :comment,
          evaluator.reply_count,
          post_id: comment.post_id,
          parent_id: comment.id
        )
      end
    end

    trait :reposted do
      transient do
        repost_count { 1 }
      end

      after(:create) do |comment, evaluator|
        create_list(:comment_repost, evaluator.repost_count, message_id: comment.id)
      end
    end
  end
end
