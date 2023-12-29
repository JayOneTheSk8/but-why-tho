class User < ApplicationRecord
  CONFIRMATION_TOKEN_EXPIRATION = 10.minutes
  MAILER_FROM_EMAIL = "no-reply@example.com".freeze # TODO: add real email address w/ full integration

  # Use password digest
  has_secure_password

  has_many :posts, dependent: :destroy

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

  def unconfirmed?
    !confirmed?
  end

  def generate_confirmation_token
    return if confirmed?

    # https://api.rubyonrails.org/classes/ActiveRecord/SignedId.html#method-i-signed_id
    signed_id expires_in: CONFIRMATION_TOKEN_EXPIRATION, purpose: :confirm_email
  end

  def send_confirmation_email!
    return if confirmed?

    confirmation_token = generate_confirmation_token
    UserMailer.confirmation(self, confirmation_token).deliver_now
  end

  private

  def downcase_email
    self.email = email.downcase
  end
end
