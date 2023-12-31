FactoryBot.define do
  factory :post do
    text { "Considering the many of them online, is this the best forum to ask a question?" }
    author_id { create(:user).id }
  end
end
