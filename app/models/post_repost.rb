class PostRepost < Repost
  belongs_to :user
  belongs_to :post, class_name: :Post, foreign_key: :message_id

  validate :other_user_content

  private

  def other_user_content
    return if post.nil?
    return if post.author_id != user_id

    errors.add(:base, "User cannot repost own content")
  end
end
