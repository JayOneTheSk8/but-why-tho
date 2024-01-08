FactoryBot.define do
  factory :comment_like do
    user
    message_id { create(:comment).id }
  end
end
