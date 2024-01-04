json.partial! "posts/post", post: @post

json.comments do
  json.array! @post.comments.sort_by(&:created_at).reverse do |comment|
    json.partial! "comments/comment", comment:
  end
end
