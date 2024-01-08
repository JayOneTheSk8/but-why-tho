FactoryBot.define do
  factory :post_like do
    user
    message_id { create(:post).id }
  end
end
