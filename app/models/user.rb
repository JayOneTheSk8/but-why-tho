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

  has_many :comment_likes, dependent: :destroy
  has_many(
    :liked_comments,
    -> { order("likes.created_at DESC") },
    through: :comment_likes,
    source: :comment
  )

  has_many :post_likes, dependent: :destroy
  has_many(
    :liked_posts,
    -> { order("likes.created_at DESC") },
    through: :post_likes,
    source: :post
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

  def likes
    results =
      ActiveRecord::Base.connection.select_all(<<~SQL.squish, "sql", [id]).to_a
        WITH user_likes as (
          SELECT
            likes.id as like_id,
            likes.created_at as liked_at,
            likes.type as like_type,
            likes.message_id as message_id
          FROM likes
          WHERE likes.user_id = $1
        ),liked_posts as (
          SELECT
            posts.id as id,
            posts.text as text,
            posts.created_at as created_at,
            post_authors.id as author_id,
            post_authors.username as author_username,
            post_authors.display_name as author_display_name,
            user_likes.like_id as like_id,
            user_likes.liked_at as liked_at,
            user_likes.like_type as like_type
          FROM posts
          INNER JOIN users post_authors
            ON posts.author_id = post_authors.id
          INNER JOIN user_likes
            ON user_likes.message_id = posts.id
            AND user_likes.like_type = 'PostLike'
          GROUP BY
            posts.id,
            post_authors.id,
            user_likes.like_id,
            user_likes.liked_at,
            user_likes.like_type
        ), liked_comments as (
          SELECT
            comments.id as id,
            comments.text as text,
            comments.created_at as created_at,
            comment_authors.id as author_id,
            comment_authors.username as author_username,
            comment_authors.display_name as author_display_name,
            user_likes.like_id as like_id,
            user_likes.liked_at as liked_at,
            user_likes.like_type as like_type
          FROM comments
          INNER JOIN users comment_authors
            ON comments.author_id = comment_authors.id
          INNER JOIN user_likes
            ON user_likes.message_id = comments.id
            AND user_likes.like_type = 'CommentLike'
          GROUP BY
            comments.id,
            comment_authors.id,
            user_likes.like_id,
            user_likes.liked_at,
            user_likes.like_type
        ), merged as (
          SELECT * FROM liked_posts
          UNION ALL
          SELECT * FROM liked_comments
        ), like_counts as (
          SELECT
            COUNT(likes.id) as like_count,
            likes.message_id as message_id,
            likes.type as message_type
          FROM likes
          INNER JOIN merged
            ON likes.type = merged.like_type
            AND likes.message_id = merged.id
          GROUP BY
            likes.type, likes.message_id
        )
        SELECT
          merged.*,
          like_counts.like_count as like_count
        FROM merged
        INNER JOIN like_counts
          ON like_counts.message_type = merged.like_type
          AND like_counts.message_id = merged.id
        ORDER BY merged.like_id DESC
      SQL

    results.map do |result|
      {
        id: result["id"],
        text: result["text"],
        created_at: result["created_at"],
        like_type: result["like_type"],
        like_count: result["like_count"],
        liked_at: result["liked_at"],
        author: {
          id: result["author_id"],
          username: result["author_username"],
          display_name: result["author_display_name"]
        }
      }
    end
  end

  private

  def ensure_session_token!
    self.session_token ||= SecureRandom.urlsafe_base64(32)
  end

  def downcase_email
    self.email = email&.downcase
  end
end
