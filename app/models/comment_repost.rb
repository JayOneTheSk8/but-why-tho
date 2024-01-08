class CommentRepost < Repost
  belongs_to :user
  belongs_to :comment, class_name: :Comment, foreign_key: :message_id
end
