FactoryBot.define do
  factory :post_repost do
    user
    message_id { create(:post).id }
  end
end
