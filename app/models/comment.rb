class Comment < ApplicationRecord
  include QuestionValidation

  belongs_to :author, class_name: :User
  belongs_to :post
  belongs_to :parent, class_name: :Comment, optional: true

  has_many(
    :replies,
    class_name: :Comment,
    foreign_key: :parent_id,
    dependent: :destroy
  )

  validate :reply_and_parent_post_match

  scope :parents, -> { where(parent_id: nil) }
  scope :replies, -> { where.not(parent_id: nil) }

  private

  def reply_and_parent_post_match
    return if parent_id.nil?
    return if post_id == parent.post_id

    errors.add(:base, "Reply and parent comment must be to the same post")
  end
end
