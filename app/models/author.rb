class Author < ApplicationRecord
  before_save :downcase_email

  validates(
    :email,
    format: {with: /\A[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}\z/},
    presence: true,
    uniqueness: true
  )
  validates(
    :username,
    presence: true,
    uniqueness: true,
    length: {maximum: 50}
  )

  private

  def downcase_email
    self.email = email.downcase
  end
end
