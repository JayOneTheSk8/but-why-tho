# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

user1 = User.create!(
  username: "coolGuy17",
  email: "livinincalabasas@dbz.com",
  password: "winnerch1ckend1nneR",
  confirmed_at: Time.current
)
user2 = User.create!(
  username: "dolly_parkins",
  email: "dolpar@gm.com",
  password: "Mov1n0nup"
)

20.times do
  Post.create!(
    text: Faker::Lorem.question(word_count: rand(5..10)),
    author: [user1, user2].sample
  )
end
