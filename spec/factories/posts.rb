FactoryBot.define do
  factory :post do
    text { Faker::Lorem.question(word_count: rand(5..10)) }
    author_id { create(:user).id }
  end
end
