case @like.type.to_sym
when :PostLike
  json.partial! "likes/post_like", like: @like
when :CommentLike
  json.partial! "likes/comment_like", like: @like
end
