# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

User.create!(
  username: "coolGuy17",
  display_name: "Cool Guy 17",
  email: "livinincalabasas@dbz.com",
  password: "winnerch1ckend1nneR",
  confirmed_at: Time.current
)
User.create!(
  username: "dolly_parkins",
  display_name: "Dolly Parkins",
  email: "dolpar@gm.com",
  password: "Mov1n0nup",
  confirmed_at: Time.current
)
User.create!(
  username: "monsieurMongo",
  display_name: "Monsieur Mongo",
  email: "mon@mongo.com",
  password: "un+i3d"
)
User.create!(
  username: "grennaGreenz143",
  display_name: "Grenna Greenz 143",
  email: "greenzzzz@more.com",
  password: "ju5t@pasS"
)

20.times do
  Post.create!(
    text: Faker::Lorem.question(word_count: rand(5..10)),
    author: User.order("RANDOM()").take
  )
end

# Parent comments
7.times do
  Comment.create!(
    text: Faker::Lorem.question(word_count: rand(5..10)),
    author: User.order("RANDOM()").take,
    post: Post.order("RANDOM()").take
  )
end

# Replies to parent comments
10.times do
  comment = Comment.parents.order("RANDOM()").take
  Comment.create!(
    text: Faker::Lorem.question(word_count: rand(5..10)),
    author: User.order("RANDOM()").take,
    post: comment.post,
    parent: comment
  )
end

# Replies to replies
replies = Comment.replies
12.times do
  reply = replies.order("RANDOM()").take
  Comment.create!(
    text: Faker::Lorem.question(word_count: rand(5..10)),
    author: User.order("RANDOM()").take,
    post: reply.post,
    parent: reply
  )
end
