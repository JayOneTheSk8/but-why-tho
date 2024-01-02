class Post < ApplicationRecord
  include QuestionValidation

  belongs_to :author, class_name: :User

  has_many :comments, dependent: :destroy
end
