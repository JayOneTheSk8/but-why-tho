class Post < ApplicationRecord
  include QuestionValidation

  belongs_to :author, class_name: :User

  has_many(
    :comments,
    -> { where(parent_id: nil) },
    dependent: :destroy
  )
  has_many(
    :likes,
    class_name: :PostLike,
    foreign_key: :message_id,
    dependent: :destroy
  )
  has_many(
    :reposts,
    class_name: :PostRepost,
    foreign_key: :message_id,
    dependent: :destroy
  )
end
