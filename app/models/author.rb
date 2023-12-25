class Author < ApplicationRecord
  CONFIRMATION_TOKEN_EXPIRATION = 10.minutes

  # Use password digest
  has_secure_password

  before_save :downcase_email

  validates(
    :email,
    format: {with: /\A[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}\z/},
    presence: true,
    uniqueness: true
  )
  validates(
    :username,
    format: {with: /\A[\w\-\.]+\z/},
    presence: true,
    uniqueness: true,
    length: {maximum: 50}
  )

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }

  def confirm!
    update!(confirmed_at: Time.current) if unconfirmed?
  end

  def confirmed?
    confirmed_at.present?
  end

  def generate_confirmation_token
    return if confirmed?

    # https://api.rubyonrails.org/classes/ActiveRecord/SignedId.html#method-i-signed_id
    signed_id expires_in: CONFIRMATION_TOKEN_EXPIRATION, purpose: :confirm_email
  end

  def unconfirmed?
    !confirmed?
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
