json.id post.id
json.text post.text
json.created_at post.created_at

# Avoid a second query that would call the child replies
json.comment_count post.comments.length

json.author do
  json.id post.author_id
  json.username post.author.username
end
