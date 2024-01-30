json.extract! user, :id, :username, :display_name, :email, :created_at

json.current_user_following(
  logged_in? && Follow.find_by(
    follower_id: current_user.id, followee_id: user.id
  ).present?
)
json.post_count user.posts.count
json.following_count user.subscriptions.count
json.follower_count user.follows.count
