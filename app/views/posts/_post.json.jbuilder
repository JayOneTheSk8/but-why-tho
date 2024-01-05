json.id post.id
json.text post.text
json.created_at post.created_at
json.comment_count post.comments.count

json.author do
  json.id post.author_id
  json.username post.author.username
  json.display_name post.author.display_name
end
