FactoryBot.define do
  factory :comment_repost do
    user
    message_id { create(:comment).id }
  end
end
