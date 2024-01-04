json.partial! "posts/post", post: @post

json.comments do
  json.array! @post.comments.sort_by(&:created_at).reverse do |comment|
    json.id comment.id
    json.text comment.text
    json.created_at comment.created_at
    json.reply_count comment.replies.count

    json.author do
      json.id comment.author_id
      json.username comment.author.username
    end
  end
end
