class CommentRepost < Repost
  belongs_to :user
  belongs_to :comment, class_name: :Comment, foreign_key: :message_id

  validate :other_user_content

  private

  def other_user_content
    return if comment.nil?
    return if comment.author_id != user_id

    errors.add(:base, "User cannot repost own content")
  end
end
