module QuestionValidation
  extend ActiveSupport::Concern

  included do
    validates :text, presence: true, length: {maximum: 200}
    validate :text_is_question
  end

  private

  def map_sql_to_message(result)
    {
      id: result["id"],
      text: result["text"],
      created_at: result["created_at"],
      comment_count: result["comment_count"],
      like_count: result["like_count"],
      repost_count: result["repost_count"],
      user_liked: result["user_liked"],
      user_reposted: result["user_reposted"],
      user_followed: result["user_followed"],
      replying_to: result["replying_to"].presence&.split(",")&.uniq,
      author: {
        id: result["author_id"],
        username: result["author_username"],
        display_name: result["author_display_name"]
      }
    }
  end

  def text_is_question
    return if text.blank?
    return unless text.last != "?" || %w[! ¡ .].any? { |chr| text.include?(chr) }

    errors.add(:base, "Text must only have questions")
  end
end
