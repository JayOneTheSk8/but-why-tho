json.extract! user, :id, :username, :display_name, :email

json.following_count user.subscriptions.count
json.follower_count user.follows.count
