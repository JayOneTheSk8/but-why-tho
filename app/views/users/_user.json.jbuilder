json.extract! user, :id, :username, :display_name, :email, :created_at

json.post_count user.posts.count
json.following_count user.subscriptions.count
json.follower_count user.follows.count
