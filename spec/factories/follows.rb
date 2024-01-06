FactoryBot.define do
  factory :follow do
    followee { create(:user) }
    follower { create(:user) }
  end
end
