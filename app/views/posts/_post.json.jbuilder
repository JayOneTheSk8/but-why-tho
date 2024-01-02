json.id post.id
json.text post.text
json.created_at post.created_at
json.author do
  json.id post.author_id
  json.username post.author.username
end
