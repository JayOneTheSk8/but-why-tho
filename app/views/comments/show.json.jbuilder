json.partial! "comments/comment", comment: @comment

json.current_user_following(
  logged_in? && Follow.find_by(
    follower_id: current_user.id, followee_id: @comment.author_id
  ).present?
)

json.post do
  json.partial! "posts/post", post: @comment.post

  json.current_user_following(
    logged_in? && Follow.find_by(
      follower_id: current_user.id, followee_id: @comment.post.author_id
    ).present?
  )
end

json.parent do
  if @comment.parent_id.present?
    json.partial! "comments/comment", comment: @comment.parent
  else
    json.null!
  end
end

json.replies do
  json.array! @comment.replies.sort_by(&:created_at).reverse do |reply|
    json.partial! "comments/comment", comment: reply
  end
end
