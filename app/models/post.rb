class Post < ApplicationRecord
  belongs_to :author, class_name: :User

  validates :text, presence: true, length: {maximum: 200}

  validate :text_is_question

  private

  def text_is_question
    return if text.blank?
    return unless text.last != "?" || %w[! ¡ .].any? { |chr| text.include?(chr) }

    errors.add(:base, "Text must only have questions")
  end
end
