json.partial! "comments/comment", comment: @comment

json.post do
  json.partial! "posts/post", post: @comment.post
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
