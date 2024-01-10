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

  has_many :comment_reposts, dependent: :destroy
  has_many(
    :reposted_comments,
    -> { order("reposts.created_at DESC") },
    through: :comment_reposts,
    source: :comment
  )

  has_many :post_reposts, dependent: :destroy
  has_many(
    :reposted_posts,
    -> { order("reposts.created_at DESC") },
    through: :post_reposts,
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

  def likes(current_user: nil)
    binds = [
      ActiveRecord::Relation::QueryAttribute.new(
        "user_id",
        id,
        ActiveRecord::Type::Integer.new
      ),
      ActiveRecord::Relation::QueryAttribute.new(
        "current_user_id",
        current_user&.id || 0,
        ActiveRecord::Type::Integer.new
      )
    ]

    results =
      ActiveRecord::Base.connection.select_all(<<~SQL.squish, "sql", binds).to_a
        WITH current_user_reposts as (
          SELECT
            reposts.id as repost_id,
            reposts.created_at as reposted_at,
            reposts.type as repost_type,
            reposts.message_id as message_id
          FROM reposts
          WHERE reposts.user_id = $2
        ), current_user_likes as (
          SELECT
            likes.id as like_id,
            likes.created_at as liked_at,
            likes.type as like_type,
            likes.message_id as message_id
          FROM likes
          WHERE likes.user_id = $2
        ), user_reposts as (
          SELECT
            reposts.id as repost_id,
            reposts.created_at as reposted_at,
            reposts.type as repost_type,
            reposts.message_id as message_id
          FROM reposts
          WHERE reposts.user_id = $1
        ), user_likes as (
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
            user_likes.like_type as like_type,
            'PostRepost' as repost_type,
            NULL as replying_to,
            (
              CASE
              WHEN current_user_likes.like_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_liked,
            (
              CASE
              WHEN current_user_reposts.repost_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_reposted,
            COUNT(
              CASE
              WHEN post_comments.parent_id IS NULL
                THEN post_comments.id
              END
            ) as comment_count
          FROM posts
          INNER JOIN users post_authors
            ON posts.author_id = post_authors.id
          INNER JOIN user_likes
            ON user_likes.like_type = 'PostLike'
            AND user_likes.message_id = posts.id
          LEFT OUTER JOIN comments post_comments
            ON post_comments.post_id = posts.id
          LEFT OUTER JOIN current_user_likes
            ON current_user_likes.like_type = 'PostLike'
            AND current_user_likes.message_id = posts.id
          LEFT OUTER JOIN current_user_reposts
            ON current_user_reposts.repost_type = 'PostRepost'
            AND current_user_reposts.message_id = posts.id
          GROUP BY
            posts.id,
            post_authors.id,
            user_likes.like_id,
            user_likes.liked_at,
            user_likes.like_type,
            current_user_likes.like_id,
            current_user_reposts.repost_id
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
            user_likes.like_type as like_type,
            'CommentRepost' as repost_type,
            array_to_string(
              ARRAY[
                (
                  CASE
                  WHEN parent_comment.id IS NOT NULL
                    THEN parent_comment_author.username
                  END
                ),
                comment_post_author.username
              ],
              ','
            ) as replying_to,
            (
              CASE
              WHEN current_user_likes.like_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_liked,
            (
              CASE
              WHEN current_user_reposts.repost_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_reposted,
            COUNT(comment_replies.id) as comment_count
          FROM comments
          INNER JOIN users comment_authors
            ON comments.author_id = comment_authors.id
          INNER JOIN user_likes
            ON user_likes.like_type = 'CommentLike'
            AND user_likes.message_id = comments.id
          INNER JOIN posts comment_post
            ON comment_post.id = comments.post_id
          INNER JOIN users comment_post_author
            ON comment_post_author.id = comment_post.author_id
          LEFT OUTER JOIN comments parent_comment
            ON parent_comment.id = comments.parent_id
          LEFT OUTER JOIN users parent_comment_author
            ON parent_comment_author.id = parent_comment.author_id
          LEFT OUTER JOIN comments comment_replies
            ON comment_replies.parent_id = comments.id
          LEFT OUTER JOIN current_user_likes
            ON current_user_likes.like_type = 'CommentLike'
            AND current_user_likes.message_id = comments.id
          LEFT OUTER JOIN current_user_reposts
            ON current_user_reposts.repost_type = 'CommentRepost'
            AND current_user_reposts.message_id = comments.id
          GROUP BY
            comments.id,
            comment_authors.id,
            user_likes.like_id,
            user_likes.liked_at,
            user_likes.like_type,
            current_user_likes.like_id,
            current_user_reposts.repost_id,
            parent_comment.id,
            comment_post_author.username,
            parent_comment_author.username
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
        ), repost_counts as (
          SELECT
            COUNT(reposts.id) as repost_count,
            reposts.message_id as message_id,
            reposts.type as message_type
          FROM reposts
          INNER JOIN merged
            ON reposts.type = merged.repost_type
            AND reposts.message_id = merged.id
          GROUP BY
            reposts.type, reposts.message_id
        )
        SELECT
          merged.*,
          like_counts.like_count as like_count,
          COALESCE(repost_counts.repost_count, 0) as repost_count
        FROM merged
        INNER JOIN like_counts
          ON like_counts.message_type = merged.like_type
          AND like_counts.message_id = merged.id
        LEFT OUTER JOIN repost_counts
          ON repost_counts.message_type = merged.repost_type
          AND repost_counts.message_id = merged.id
        ORDER BY merged.like_id DESC
      SQL

    results.map do |result|
      {
        id: result["id"],
        text: result["text"],
        created_at: result["created_at"],
        like_type: result["like_type"],
        like_count: result["like_count"],
        repost_count: result["repost_count"],
        comment_count: result["comment_count"],
        liked_at: result["liked_at"],
        user_liked: result["user_liked"],
        user_reposted: result["user_reposted"],
        replying_to: result["replying_to"].presence&.split(","),
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
