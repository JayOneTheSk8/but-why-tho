# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

u1 = User.create!(
  username: "coolGuy17",
  display_name: "Cool Guy 17",
  email: "livinincalabasas@dbz.com",
  password: "winnerch1ckend1nneR",
  confirmed_at: Time.current
)
u2 = User.create!(
  username: "dolly_parkins",
  display_name: "Dolly Parkins",
  email: "dolpar@gm.com",
  password: "Mov1n0nup",
  confirmed_at: Time.current
)
u3 = User.create!(
  username: "monsieurMongo",
  display_name: "Monsieur Mongo",
  email: "mon@mongo.com",
  password: "un+i3d"
)
u4 = User.create!(
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

Follow.create!(follower: u1, followee: u2)
Follow.create!(follower: u3, followee: u2)
Follow.create!(follower: u4, followee: u2)
Follow.create!(follower: u2, followee: u1)
Follow.create!(follower: u1, followee: u3)
Follow.create!(follower: u4, followee: u3)

cr1_user = u4
cr2_user = u3
comments = Comment.order("RANDOM()").to_a
comments.slice(0, 8).each.with_index do |c, idx|
  if idx.even?
    if c.author_id == cr1_user.id
      CommentRepost.create!(
        user: cr2_user,
        message_id: c.id
      )
    else
      CommentRepost.create!(
        user: cr1_user,
        message_id: c.id
      )
    end
  elsif c.author_id == cr2_user.id
    CommentRepost.create!(
      user: cr1_user,
      message_id: c.id
    )
  else
    CommentRepost.create!(
      user: cr2_user,
      message_id: c.id
    )
  end
end

cr3_user = u1
cr4_user = u2
comments.slice(8, 16).each.with_index do |c, idx|
  if idx.even?
    if c.author_id == cr3_user.id
      CommentRepost.create!(
        user: cr4_user,
        message_id: c.id
      )
    else
      CommentRepost.create!(
        user: cr3_user,
        message_id: c.id
      )
    end
  elsif c.author_id == cr4_user.id
    CommentRepost.create!(
      user: cr3_user,
      message_id: c.id
    )
  else
    CommentRepost.create!(
      user: cr4_user,
      message_id: c.id
    )
  end
end

pr1_user = u4
pr2_user = u3
posts = Post.order("RANDOM()").to_a
posts.slice(0, 8).each.with_index do |po, idx|
  if idx.even?
    if po.author_id == pr1_user.id
      PostRepost.create!(
        user: pr2_user,
        message_id: po.id
      )
    else
      PostRepost.create!(
        user: pr1_user,
        message_id: po.id
      )
    end
  elsif po.author_id == pr2_user.id
    PostRepost.create!(
      user: pr1_user,
      message_id: po.id
    )
  else
    PostRepost.create!(
      user: pr2_user,
      message_id: po.id
    )
  end
end

pr3_user = u1
pr4_user = u2
posts.slice(8, 16).each.with_index do |po, idx|
  if idx.even?
    if po.author_id == pr3_user.id
      PostRepost.create!(
        user: pr4_user,
        message_id: po.id
      )
    else
      PostRepost.create!(
        user: pr3_user,
        message_id: po.id
      )
    end
  elsif po.author_id == pr4_user.id
    PostRepost.create!(
      user: pr3_user,
      message_id: po.id
    )
  else
    PostRepost.create!(
      user: pr4_user,
      message_id: po.id
    )
  end
end

cl1_user = u4
cl2_user = u3
comments = Comment.order("RANDOM()").to_a
comments.slice(0, 8).each.with_index do |c, idx|
  if idx.even?
    CommentLike.create!(
      user: cl1_user,
      message_id: c.id
    )
  else
    CommentLike.create!(
      user: cl2_user,
      message_id: c.id
    )
  end
end

cl3_user = u1
cl4_user = u2
comments.slice(8, 16).each.with_index do |c, idx|
  if idx.even?
    CommentLike.create!(
      user: cl3_user,
      message_id: c.id
    )
  else
    CommentLike.create!(
      user: cl4_user,
      message_id: c.id
    )
  end
end

pl1_user = u4
pl2_user = u3
posts = Post.order("RANDOM()").to_a
posts.slice(0, 8).each.with_index do |po, idx|
  if idx.even?
    PostLike.create!(
      user: pl1_user,
      message_id: po.id
    )
  else
    PostLike.create!(
      user: pl2_user,
      message_id: po.id
    )
  end
end

pl3_user = u1
pl4_user = u2
posts.slice(8, 16).each.with_index do |po, idx|
  if idx.even?
    PostLike.create!(
      user: pl3_user,
      message_id: po.id
    )
  else
    PostLike.create!(
      user: pl4_user,
      message_id: po.id
    )
  end
end
