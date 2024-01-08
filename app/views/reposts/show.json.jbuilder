case @repost.type.to_sym
when :PostRepost
  json.partial! "reposts/post_repost", repost: @repost
when :CommentRepost
  json.partial! "reposts/comment_repost", repost: @repost
end
