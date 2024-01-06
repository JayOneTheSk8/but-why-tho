class User < ApplicationRecord
  CONFIRMATION_TOKEN_EXPIRATION = 10.minutes
  MAILER_FROM_EMAIL = "no-reply@example.com".freeze # TODO: add real email address w/ full integration

  # Use password digest
  has_secure_password

  has_many(
    :posts,
    foreign_key: :author_id,
    dependent: :destroy
  )
  has_many(
    :comments,
    -> { where(parent_id: nil) },
    foreign_key: :author_id,
    dependent: :destroy
  )
  has_many(
    :replies,
    -> { where.not(parent_id: nil) },
    class_name: :Comment,
    foreign_key: :author_id,
    dependent: :destroy
  )

  has_many(
    :subscriptions,
    foreign_key: :follower_id,
    class_name: :Follow,
    dependent: :destroy
  )
  has_many(
    :followed_users,
    -> { order("follows.created_at DESC") },
    through: :subscriptions,
    source: :followee
  )
  has_many(
    :follows,
    foreign_key: :followee_id,
    dependent: :destroy
  )
  has_many(
    :followers,
    -> { order("follows.created_at DESC") },
    through: :follows,
    source: :follower
  )

  after_initialize :ensure_session_token!
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

  validates :display_name, presence: true, length: {maximum: 50}
  validates :session_token, presence: true, uniqueness: true

  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }

  def self.find_by_credentials(login, password)
    User
      .where(username: login).or(User.where(email: login))
      .first
      .authenticate(password)
      .presence
  end

  def confirm!
    update!(confirmed_at: Time.current) if unconfirmed?
  end

  def confirmed?
    confirmed_at.present?
  end

  def unconfirmed?
    !confirmed?
  end

  def reset_session_token!
    self.session_token = SecureRandom.urlsafe_base64(32)
    save!
    session_token
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

  def ensure_session_token!
    self.session_token ||= SecureRandom.urlsafe_base64(32)
  end

  def downcase_email
    self.email = email&.downcase
  end
end
