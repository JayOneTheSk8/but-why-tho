class Post < ApplicationRecord
  include QuestionValidation

  belongs_to :author, class_name: :User

  has_many(
    :comments,
    -> { where(parent_id: nil) },
    dependent: :destroy
  )
end
