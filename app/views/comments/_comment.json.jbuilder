json.id comment.id
json.text comment.text
json.created_at comment.created_at
json.reply_count comment.replies.count

json.author do
  json.id comment.author_id
  json.username comment.author.username
end
