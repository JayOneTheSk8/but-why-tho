json.array! @comments do |comment|
  json.partial!("comments/comment", comment:)

  json.post do
    json.partial! "posts/post", post: comment.post
  end

  json.parent do
    if comment.parent_id.present?
      json.partial! "comments/comment", comment: comment.parent
    else
      json.null!
    end
  end
end
