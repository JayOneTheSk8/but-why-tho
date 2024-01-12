json.partial! "posts/post", post: @post

json.current_user_following(
  logged_in? && Follow.find_by(
    follower_id: current_user.id, followee_id: @post.author_id
  ).present?
)

json.comments do
  json.array! @post.comments.sort_by(&:created_at).reverse do |comment|
    json.partial! "comments/comment", comment:
  end
end
