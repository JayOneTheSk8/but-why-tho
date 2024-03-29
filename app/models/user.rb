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

  def self.search_users(search_text, current_user: nil, limit: 100)
    binds = [
      ActiveRecord::Relation::QueryAttribute.new(
        "current_user_id",
        current_user&.id || 0,
        ActiveRecord::Type::Integer.new
      ),
      ActiveRecord::Relation::QueryAttribute.new(
        "search_text",
        "%#{search_text.gsub('%', '\\%')}%",
        ActiveRecord::Type::String.new
      ),
      ActiveRecord::Relation::QueryAttribute.new(
        "search_limit",
        limit,
        ActiveRecord::Type::Integer.new
      )
    ]

    ActiveRecord::Base.connection.select_all(<<~SQL.squish, "User Search", binds).to_a
      WITH current_user_followers as (
        SELECT
          follows.id as follow_id,
          follows.follower_id as follower_id
        FROM follows
        WHERE follows.followee_id = $1
      ), current_user_subscriptions as (
        SELECT
          follows.id as follow_id,
          follows.followee_id as followee_id
        FROM follows
        WHERE follows.follower_id = $1
      ), found_users as (
        SELECT
          users.id as id,
          users.username as username,
          users.display_name as display_name,
          (
            CASE
            WHEN current_user_subscriptions.follow_id IS NOT NULL
              THEN TRUE
            ELSE
              FALSE
            END
          ) as current_user_following,
          (
            CASE
            WHEN current_user_followers.follow_id IS NOT NULL
              THEN TRUE
            ELSE
              FALSE
            END
          ) as following_current_user
        FROM users
        LEFT OUTER JOIN follows followers
          ON followers.followee_id = users.id
        LEFT OUTER JOIN follows followed_users
          ON followed_users.follower_id = users.id
        LEFT OUTER JOIN current_user_subscriptions
          ON current_user_subscriptions.followee_id = users.id
        LEFT OUTER JOIN current_user_followers
          ON current_user_followers.follower_id = users.id
        WHERE username ILIKE $2 OR display_name ILIKE $2
        GROUP BY
          users.id,
          current_user_subscriptions.follow_id,
          current_user_followers.follow_id
      ), follower_counts as (
        SELECT
          COUNT(follows.id) as follower_count,
          follows.followee_id as user_id
        FROM follows
        INNER JOIN found_users
          ON found_users.id = follows.followee_id
        GROUP BY
          follows.followee_id
      ), followed_user_counts as (
        SELECT
          COUNT(follows.id) as followed_user_count,
          follows.follower_id as user_id
        FROM follows
        INNER JOIN found_users
          ON found_users.id = follows.follower_id
        GROUP BY
          follows.follower_id
      )
      SELECT
        found_users.*,
        COALESCE(follower_counts.follower_count, 0) as follower_count,
        COALESCE(followed_user_counts.followed_user_count, 0) as followed_user_count,
        (
          (
            CASE
            WHEN found_users.id = $1
              THEN 1000
            ELSE
              0
            END
          ) +
          (
            CASE
            WHEN current_user_subscriptions.follow_id IS NOT NULL
              THEN 15
            ELSE
              0
            END
          ) +
          (COALESCE(follower_counts.follower_count, 0) * 3) +
          (COALESCE(followed_user_counts.followed_user_count, 0) * 1)
        ) as user_rating
      FROM found_users
      LEFT OUTER JOIN follower_counts
        ON follower_counts.user_id = found_users.id
      LEFT OUTER JOIN followed_user_counts
        ON followed_user_counts.user_id = found_users.id
      LEFT OUTER JOIN current_user_subscriptions
        ON current_user_subscriptions.followee_id = found_users.id
      ORDER BY
        user_rating DESC,
        found_users.id DESC
      LIMIT $3
    SQL
  end

  def likes(current_user: nil)
    binds = bind_id_with_current_user_id_for_query(current_user)

    results =
      ActiveRecord::Base.connection.select_all(<<~SQL.squish, "User Liked Posts", binds).to_a
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
        ), current_user_subscriptions as (
          SELECT
            follows.id as follow_id,
            follows.followee_id as followee_id
          FROM follows
          WHERE follows.follower_id = $2
        ), user_reposts as (
          SELECT
            reposts.id as repost_id,
            reposts.created_at as reposted_at,
            reposts.type as repost_type,
            reposts.message_id as message_id,
            reposter.username as reposter_username,
            reposter.display_name as reposter_display_name,
            reposter.id as reposter_id
          FROM reposts
          INNER JOIN users reposter
            ON reposter.id = reposts.user_id
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
            (
              CASE
              WHEN current_user_subscriptions.follow_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_followed,
            (
              CASE
              WHEN user_reposts.repost_id IS NOT NULL
                THEN
                  CASE
                  WHEN user_reposts.reposter_id = $2
                    THEN 'You'
                  ELSE user_reposts.reposter_display_name
                  END
              ELSE
                NULL
              END
            ) reposted_by,
            (
              CASE
              WHEN user_reposts.repost_id IS NOT NULL
                THEN user_reposts.reposter_username
              ELSE
                NULL
              END
            ) reposted_by_username,
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
          LEFT OUTER JOIN current_user_subscriptions
            ON current_user_subscriptions.followee_id = posts.author_id
          LEFT OUTER JOIN user_reposts
            ON user_reposts.repost_type = 'PostRepost'
            AND user_reposts.message_id = posts.id
          GROUP BY
            posts.id,
            post_authors.id,
            user_likes.like_id,
            user_likes.liked_at,
            user_likes.like_type,
            current_user_likes.like_id,
            current_user_reposts.repost_id,
            current_user_subscriptions.follow_id,
            user_reposts.repost_id,
            user_reposts.reposter_display_name,
            user_reposts.reposter_username,
            user_reposts.reposter_id
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
            (
              CASE
              WHEN current_user_subscriptions.follow_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_followed,
            (
              CASE
              WHEN user_reposts.repost_id IS NOT NULL
                THEN
                  CASE
                  WHEN user_reposts.reposter_id = $2
                    THEN 'You'
                  ELSE user_reposts.reposter_display_name
                  END
              ELSE
                NULL
              END
            ) reposted_by,
            (
              CASE
              WHEN user_reposts.repost_id IS NOT NULL
                THEN user_reposts.reposter_username
              ELSE
                NULL
              END
            ) reposted_by_username,
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
          LEFT OUTER JOIN current_user_subscriptions
            ON current_user_subscriptions.followee_id = comments.author_id
          LEFT OUTER JOIN user_reposts
            ON user_reposts.repost_type = 'CommentRepost'
            AND user_reposts.message_id = comments.id
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
            parent_comment_author.username,
            current_user_subscriptions.follow_id,
            user_reposts.repost_id,
            user_reposts.reposter_display_name,
            user_reposts.reposter_username,
            user_reposts.reposter_id
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
        reposted_by: result["reposted_by"],
        reposted_by_username: result["reposted_by_username"],
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
  end

  def linked_posts(current_user: nil)
    binds = bind_id_with_current_user_id_for_query(current_user)

    results =
      ActiveRecord::Base.connection.select_all(<<~SQL.squish, "User Linked Posts", binds).to_a
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
        ), current_user_subscriptions as (
          SELECT
            follows.id as follow_id,
            follows.followee_id as followee_id
          FROM follows
          WHERE follows.follower_id = $2
        ), user_reposts as (
          SELECT
            reposts.id as repost_id,
            reposts.created_at as reposted_at,
            reposts.type as repost_type,
            reposts.message_id as message_id,
            reposter.username as reposter_username,
            reposter.display_name as reposter_display_name,
            reposter.id as reposter_id
          FROM reposts
          INNER JOIN users reposter
            ON reposter.id = reposts.user_id
          WHERE reposts.user_id = $1
        ), reposted_posts as (
          SELECT
            posts.id as id,
            posts.text as text,
            posts.created_at as created_at,
            post_authors.id as author_id,
            post_authors.username as author_username,
            post_authors.display_name as author_display_name,
            user_reposts.reposted_at as post_date,
            (
              CASE
              WHEN user_reposts.reposter_id = $2
                THEN 'You'
              ELSE user_reposts.reposter_display_name
              END
            ) as reposted_by,
            user_reposts.reposter_username as reposted_by_username,
            user_reposts.repost_type as post_type,
            user_reposts.repost_type as repost_type,
            'PostLike' as like_type,
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
            (
              CASE
              WHEN current_user_subscriptions.follow_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_followed,
            COUNT(
              CASE
              WHEN post_comments.parent_id IS NULL
                THEN post_comments.id
              END
            ) as comment_count
          FROM posts
          INNER JOIN users post_authors
            ON posts.author_id = post_authors.id
          INNER JOIN user_reposts
            ON user_reposts.repost_type = 'PostRepost'
            AND user_reposts.message_id = posts.id
          LEFT OUTER JOIN comments post_comments
            ON post_comments.post_id = posts.id
          LEFT OUTER JOIN current_user_likes
            ON current_user_likes.like_type = 'PostLike'
            AND current_user_likes.message_id = posts.id
          LEFT OUTER JOIN current_user_reposts
            ON current_user_reposts.repost_type = 'PostRepost'
            AND current_user_reposts.message_id = posts.id
          LEFT OUTER JOIN current_user_subscriptions
            ON current_user_subscriptions.followee_id = posts.author_id
          GROUP BY
            posts.id,
            post_authors.id,
            user_reposts.repost_type,
            user_reposts.reposted_at,
            user_reposts.reposter_display_name,
            user_reposts.reposter_username,
            user_reposts.reposter_id,
            current_user_likes.like_id,
            current_user_reposts.repost_id,
            current_user_subscriptions.follow_id
        ), reposted_comments as (
          SELECT
            comments.id as id,
            comments.text as text,
            comments.created_at as created_at,
            comment_authors.id as author_id,
            comment_authors.username as author_username,
            comment_authors.display_name as author_display_name,
            user_reposts.reposted_at as post_date,
            (
              CASE
              WHEN user_reposts.reposter_id = $2
                THEN 'You'
              ELSE user_reposts.reposter_display_name
              END
            ) as reposted_by,
            user_reposts.reposter_username as reposted_by_username,
            user_reposts.repost_type as post_type,
            user_reposts.repost_type as repost_type,
            'CommentLike' as like_type,
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
            (
              CASE
              WHEN current_user_subscriptions.follow_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_followed,
            COUNT(comment_replies.id) as comment_count
          FROM comments
          INNER JOIN users comment_authors
            ON comments.author_id = comment_authors.id
          INNER JOIN user_reposts
            ON user_reposts.repost_type = 'CommentRepost'
            AND user_reposts.message_id = comments.id
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
          LEFT OUTER JOIN current_user_subscriptions
            ON current_user_subscriptions.followee_id = comments.author_id
          GROUP BY
            comments.id,
            comment_authors.id,
            user_reposts.repost_type,
            user_reposts.reposted_at,
            user_reposts.reposter_display_name,
            user_reposts.reposter_username,
            user_reposts.reposter_id,
            current_user_likes.like_id,
            current_user_reposts.repost_id,
            parent_comment.id,
            comment_post_author.username,
            parent_comment_author.username,
            current_user_subscriptions.follow_id
        ), user_posts as (
          SELECT
            posts.id as id,
            posts.text as text,
            posts.created_at as created_at,
            post_authors.id as author_id,
            post_authors.username as author_username,
            post_authors.display_name as author_display_name,
            posts.created_at as post_date,
            NULL as reposted_by,
            NULL as reposted_by_username,
            'Post' as post_type,
            'PostRepost' as repost_type,
            'PostLike' as like_type,
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
            (
              CASE
              WHEN current_user_subscriptions.follow_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_followed,
            COUNT(
              CASE
              WHEN post_comments.parent_id IS NULL
                THEN post_comments.id
              END
            ) as comment_count
          FROM posts
          INNER JOIN users post_authors
            ON posts.author_id = post_authors.id
          LEFT OUTER JOIN comments post_comments
            ON post_comments.post_id = posts.id
          LEFT OUTER JOIN current_user_likes
            ON current_user_likes.like_type = 'PostLike'
            AND current_user_likes.message_id = posts.id
          LEFT OUTER JOIN current_user_reposts
            ON current_user_reposts.repost_type = 'PostRepost'
            AND current_user_reposts.message_id = posts.id
          LEFT OUTER JOIN current_user_subscriptions
            ON current_user_subscriptions.followee_id = posts.author_id
          WHERE posts.author_id = $1
          GROUP BY
            posts.id,
            post_authors.id,
            current_user_likes.like_id,
            current_user_reposts.repost_id,
            current_user_subscriptions.follow_id
        ), merged as (
          SELECT * FROM reposted_posts
          UNION ALL
          SELECT * FROM reposted_comments
          UNION ALL
          SELECT * FROM user_posts
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
          COALESCE(like_counts.like_count, 0) as like_count,
          COALESCE(repost_counts.repost_count, 0) as repost_count
        FROM merged
        LEFT OUTER JOIN like_counts
          ON like_counts.message_type = merged.like_type
          AND like_counts.message_id = merged.id
        LEFT OUTER JOIN repost_counts
          ON repost_counts.message_type = merged.repost_type
          AND repost_counts.message_id = merged.id
        ORDER BY merged.post_date DESC
      SQL

    results.map do |result|
      {
        id: result["id"],
        text: result["text"],
        created_at: result["created_at"],
        post_type: result["post_type"],
        like_count: result["like_count"],
        repost_count: result["repost_count"],
        comment_count: result["comment_count"],
        post_date: result["post_date"],
        reposted_by: result["reposted_by"],
        reposted_by_username: result["reposted_by_username"],
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
  end

  def linked_comments(current_user: nil)
    binds = bind_id_with_current_user_id_for_query(current_user)

    results =
      ActiveRecord::Base.connection.select_all(<<~SQL.squish, "User Linked Comments", binds).to_a
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
        ), current_user_subscriptions as (
          SELECT
            follows.id as follow_id,
            follows.followee_id as followee_id
          FROM follows
          WHERE follows.follower_id = $2
        ), user_reposts as (
          SELECT
            reposts.id as repost_id,
            reposts.created_at as reposted_at,
            reposts.type as repost_type,
            reposts.message_id as message_id,
            reposter.username as reposter_username,
            reposter.display_name as reposter_display_name,
            reposter.id as reposter_id
          FROM reposts
          INNER JOIN users reposter
            ON reposter.id = reposts.user_id
          WHERE reposts.user_id = $1
        ), reposted_comments as (
          SELECT
            comments.id as id,
            comments.text as text,
            comments.created_at as created_at,
            comment_authors.id as author_id,
            comment_authors.username as author_username,
            comment_authors.display_name as author_display_name,
            user_reposts.reposted_at as post_date,
            (
              CASE
              WHEN user_reposts.reposter_id = $2
                THEN 'You'
              ELSE user_reposts.reposter_display_name
              END
            ) as reposted_by,
            user_reposts.reposter_username as reposted_by_username,
            user_reposts.repost_type as post_type,
            user_reposts.repost_type as repost_type,
            'CommentLike' as like_type,
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
            (
              CASE
              WHEN current_user_subscriptions.follow_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_followed,
            COUNT(comment_replies.id) as comment_count
          FROM comments
          INNER JOIN users comment_authors
            ON comments.author_id = comment_authors.id
          INNER JOIN user_reposts
            ON user_reposts.repost_type = 'CommentRepost'
            AND user_reposts.message_id = comments.id
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
          LEFT OUTER JOIN current_user_subscriptions
            ON current_user_subscriptions.followee_id = comments.author_id
          GROUP BY
            comments.id,
            comment_authors.id,
            user_reposts.repost_type,
            user_reposts.reposted_at,
            user_reposts.reposter_display_name,
            user_reposts.reposter_username,
            user_reposts.reposter_id,
            current_user_likes.like_id,
            current_user_reposts.repost_id,
            parent_comment.id,
            comment_post_author.username,
            parent_comment_author.username,
            current_user_subscriptions.follow_id
        ), user_comments as (
          SELECT
            comments.id as id,
            comments.text as text,
            comments.created_at as created_at,
            comment_authors.id as author_id,
            comment_authors.username as author_username,
            comment_authors.display_name as author_display_name,
            comments.created_at as post_date,
            NULL as reposted_by,
            NULL as reposted_by_username,
            'Comment' as post_type,
            'CommentRepost' as repost_type,
            'CommentLike' as like_type,
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
            (
              CASE
              WHEN current_user_subscriptions.follow_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_followed,
            COUNT(comment_replies.id) as comment_count
          FROM comments
          INNER JOIN users comment_authors
            ON comments.author_id = comment_authors.id
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
          LEFT OUTER JOIN current_user_subscriptions
            ON current_user_subscriptions.followee_id = comments.author_id
          WHERE comments.author_id = $1
          GROUP BY
            comments.id,
            comment_authors.id,
            current_user_likes.like_id,
            current_user_reposts.repost_id,
            parent_comment.id,
            comment_post_author.username,
            parent_comment_author.username,
            current_user_subscriptions.follow_id
        ), merged as (
          SELECT * FROM reposted_comments
          UNION ALL
          SELECT * FROM user_comments
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
          COALESCE(like_counts.like_count, 0) as like_count,
          COALESCE(repost_counts.repost_count, 0) as repost_count
        FROM merged
        LEFT OUTER JOIN like_counts
          ON like_counts.message_type = merged.like_type
          AND like_counts.message_id = merged.id
        LEFT OUTER JOIN repost_counts
          ON repost_counts.message_type = merged.repost_type
          AND repost_counts.message_id = merged.id
        ORDER BY merged.post_date DESC
      SQL

    results.map do |result|
      {
        id: result["id"],
        text: result["text"],
        created_at: result["created_at"],
        post_type: result["post_type"],
        like_count: result["like_count"],
        repost_count: result["repost_count"],
        comment_count: result["comment_count"],
        post_date: result["post_date"],
        user_liked: result["user_liked"],
        reposted_by: result["reposted_by"],
        reposted_by_username: result["reposted_by_username"],
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
  end

  def followed_posts_and_comments
    binds = [
      ActiveRecord::Relation::QueryAttribute.new(
        "current_user_id",
        id,
        ActiveRecord::Type::Integer.new
      )
    ]

    results =
      ActiveRecord::Base.connection.select_all(<<~SQL.squish, "Following Posts", binds).to_a
        WITH current_user_reposts as (
          SELECT
            reposts.id as repost_id,
            reposts.created_at as reposted_at,
            reposts.type as repost_type,
            reposts.message_id as message_id,
            reposter.display_name as reposter_display_name,
            reposter.username as reposter_username,
            reposter.id as reposter_id
          FROM reposts
          INNER JOIN users reposter
            ON reposter.id = reposts.user_id
          WHERE reposts.user_id = $1
        ), current_user_likes as (
          SELECT
            likes.id as like_id,
            likes.created_at as liked_at,
            likes.type as like_type,
            likes.message_id as message_id
          FROM likes
          WHERE likes.user_id = $1
        ), current_user_subscriptions as (
          SELECT
            follows.id as follow_id,
            follows.followee_id as followee_id
          FROM follows
          WHERE follows.follower_id = $1
        ), followee_reposts as (
          SELECT
            reposts.id as repost_id,
            reposts.created_at as reposted_at,
            reposts.type as repost_type,
            reposts.message_id as message_id,
            reposter.display_name as reposter_display_name,
            reposter.username as reposter_username,
            reposter.id as reposter_id
          FROM reposts
          INNER JOIN users reposter
            ON reposter.id = reposts.user_id
          INNER JOIN current_user_subscriptions
            ON current_user_subscriptions.followee_id = reposts.user_id
        ), followee_reposted_posts as (
          SELECT
            posts.id as id,
            posts.text as text,
            posts.created_at as created_at,
            post_authors.id as author_id,
            post_authors.username as author_username,
            post_authors.display_name as author_display_name,
            followee_reposts.reposted_at as post_date,
            followee_reposts.repost_type as post_type,
            followee_reposts.repost_type as repost_type,
            followee_reposts.reposter_display_name as reposted_by,
            followee_reposts.reposter_username as reposted_by_username,
            'PostLike' as like_type,
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
            (
              CASE
              WHEN current_user_subscriptions.follow_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_followed,
            COUNT(
              CASE
              WHEN post_comments.parent_id IS NULL
                THEN post_comments.id
              END
            ) as comment_count
          FROM posts
          INNER JOIN users post_authors
            ON posts.author_id = post_authors.id
          INNER JOIN followee_reposts
            ON followee_reposts.repost_type = 'PostRepost'
            AND followee_reposts.message_id = posts.id
          LEFT OUTER JOIN comments post_comments
            ON post_comments.post_id = posts.id
          LEFT OUTER JOIN current_user_likes
            ON current_user_likes.like_type = 'PostLike'
            AND current_user_likes.message_id = posts.id
          LEFT OUTER JOIN current_user_reposts
            ON current_user_reposts.repost_type = 'PostRepost'
            AND current_user_reposts.message_id = posts.id
          LEFT OUTER JOIN current_user_subscriptions
            ON current_user_subscriptions.followee_id = posts.author_id
          GROUP BY
            posts.id,
            post_authors.id,
            followee_reposts.repost_type,
            followee_reposts.reposted_at,
            followee_reposts.reposter_display_name,
            followee_reposts.reposter_username,
            current_user_likes.like_id,
            current_user_reposts.repost_id,
            current_user_subscriptions.follow_id
        ), followee_reposted_comments as (
          SELECT
            comments.id as id,
            comments.text as text,
            comments.created_at as created_at,
            comment_authors.id as author_id,
            comment_authors.username as author_username,
            comment_authors.display_name as author_display_name,
            followee_reposts.reposted_at as post_date,
            followee_reposts.repost_type as post_type,
            followee_reposts.repost_type as repost_type,
            followee_reposts.reposter_display_name as reposted_by,
            followee_reposts.reposter_username as reposted_by_username,
            'CommentLike' as like_type,
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
            (
              CASE
              WHEN current_user_subscriptions.follow_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_followed,
            COUNT(comment_replies.id) as comment_count
          FROM comments
          INNER JOIN users comment_authors
            ON comments.author_id = comment_authors.id
          INNER JOIN followee_reposts
            ON followee_reposts.repost_type = 'CommentRepost'
            AND followee_reposts.message_id = comments.id
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
          LEFT OUTER JOIN current_user_subscriptions
            ON current_user_subscriptions.followee_id = comments.author_id
          GROUP BY
            comments.id,
            comment_authors.id,
            followee_reposts.repost_type,
            followee_reposts.reposted_at,
            followee_reposts.reposter_display_name,
            followee_reposts.reposter_username,
            parent_comment.id,
            comment_post_author.username,
            parent_comment_author.username,
            current_user_likes.like_id,
            current_user_reposts.repost_id,
            current_user_subscriptions.follow_id
        ), followee_posts as (
          SELECT
            posts.id as id,
            posts.text as text,
            posts.created_at as created_at,
            post_authors.id as author_id,
            post_authors.username as author_username,
            post_authors.display_name as author_display_name,
            posts.created_at as post_date,
            'Post' as post_type,
            'PostRepost' as repost_type,
            NULL as reposted_by,
            NULL as reposted_by_username,
            'PostLike' as like_type,
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
            (
              CASE
              WHEN current_user_subscriptions.follow_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_followed,
            COUNT(
              CASE
              WHEN post_comments.parent_id IS NULL
                THEN post_comments.id
              END
            ) as comment_count
          FROM posts
          INNER JOIN users post_authors
            ON posts.author_id = post_authors.id
          INNER JOIN current_user_subscriptions
            ON current_user_subscriptions.followee_id = post_authors.id
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
            current_user_subscriptions.follow_id,
            current_user_likes.like_id,
            current_user_reposts.repost_id
        ), user_reposted_posts as (
          SELECT
            posts.id as id,
            posts.text as text,
            posts.created_at as created_at,
            post_authors.id as author_id,
            post_authors.username as author_username,
            post_authors.display_name as author_display_name,
            current_user_reposts.reposted_at as post_date,
            current_user_reposts.repost_type as post_type,
            current_user_reposts.repost_type as repost_type,
            'You' as reposted_by,
            current_user_reposts.reposter_username as reposted_by_username,
            'PostLike' as like_type,
            NULL as replying_to,
            (
              CASE
              WHEN current_user_likes.like_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_liked,
            TRUE as user_reposted,
            (
              CASE
              WHEN current_user_subscriptions.follow_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_followed,
            COUNT(
              CASE
              WHEN post_comments.parent_id IS NULL
                THEN post_comments.id
              END
            ) as comment_count
          FROM posts
          INNER JOIN users post_authors
            ON posts.author_id = post_authors.id
          INNER JOIN current_user_reposts
            ON current_user_reposts.repost_type = 'PostRepost'
            AND current_user_reposts.message_id = posts.id
          LEFT OUTER JOIN comments post_comments
            ON post_comments.post_id = posts.id
          LEFT OUTER JOIN current_user_subscriptions
            ON current_user_subscriptions.followee_id = post_authors.id
          LEFT OUTER JOIN current_user_likes
            ON current_user_likes.like_type = 'PostLike'
            AND current_user_likes.message_id = posts.id
          GROUP BY
            posts.id,
            post_authors.id,
            current_user_likes.like_id,
            current_user_reposts.repost_id,
            current_user_reposts.reposted_at,
            current_user_reposts.reposter_display_name,
            current_user_reposts.reposter_username,
            current_user_reposts.repost_type,
            current_user_subscriptions.follow_id
        ), user_reposted_comments as (
          SELECT
            comments.id as id,
            comments.text as text,
            comments.created_at as created_at,
            comment_authors.id as author_id,
            comment_authors.username as author_username,
            comment_authors.display_name as author_display_name,
            current_user_reposts.reposted_at as post_date,
            current_user_reposts.repost_type as post_type,
            current_user_reposts.repost_type as repost_type,
            'You' as reposted_by,
            current_user_reposts.reposter_username as reposted_by_username,
            'CommentLike' as like_type,
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
            TRUE as user_reposted,
            (
              CASE
              WHEN current_user_subscriptions.follow_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_followed,
            COUNT(comment_replies.id) as comment_count
          FROM comments
          INNER JOIN users comment_authors
            ON comments.author_id = comment_authors.id
          INNER JOIN current_user_reposts
            ON current_user_reposts.repost_type = 'CommentRepost'
            AND current_user_reposts.message_id = comments.id
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
          LEFT OUTER JOIN current_user_subscriptions
            ON current_user_subscriptions.followee_id = comment_authors.id
          LEFT OUTER JOIN current_user_likes
            ON current_user_likes.like_type = 'CommentLike'
            AND current_user_likes.message_id = comments.id
          GROUP BY
            comments.id,
            comment_authors.id,
            current_user_reposts.repost_id,
            current_user_reposts.repost_type,
            current_user_reposts.reposted_at,
            current_user_reposts.reposter_display_name,
            current_user_reposts.reposter_username,
            current_user_subscriptions.follow_id,
            current_user_likes.like_id,
            parent_comment.id,
            comment_post_author.username,
            parent_comment_author.username
        ), user_posts as (
          SELECT
            posts.id as id,
            posts.text as text,
            posts.created_at as created_at,
            post_authors.id as author_id,
            post_authors.username as author_username,
            post_authors.display_name as author_display_name,
            posts.created_at as post_date,
            'Post' as post_type,
            'PostRepost' as repost_type,
            NULL as reposted_by,
            NULL as reposted_by_username,
            'PostLike' as like_type,
            NULL as replying_to,
            (
              CASE
              WHEN current_user_likes.like_id IS NOT NULL
                THEN TRUE
              ELSE
                FALSE
              END
            ) user_liked,
            FALSE as user_reposted,
            FALSE as user_followed,
            COUNT(
              CASE
              WHEN post_comments.parent_id IS NULL
                THEN post_comments.id
              END
            ) as comment_count
          FROM posts
          INNER JOIN users post_authors
            ON posts.author_id = post_authors.id
          LEFT OUTER JOIN comments post_comments
            ON post_comments.post_id = posts.id
          LEFT OUTER JOIN current_user_likes
            ON current_user_likes.like_type = 'PostLike'
            AND current_user_likes.message_id = posts.id
          WHERE posts.author_id = $1
          GROUP BY
            posts.id,
            post_authors.id,
            current_user_likes.like_id
        ), full_collection as (
          SELECT * FROM followee_reposted_posts
          UNION ALL
          SELECT * FROM followee_reposted_comments
          UNION ALL
          SELECT * FROM followee_posts
          UNION ALL
          SELECT * FROM user_reposted_posts
          UNION ALL
          SELECT * FROM user_reposted_comments
          UNION ALL
          SELECT * FROM user_posts
        ), partitioned as (
          SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY post_type, id ORDER BY post_date DESC) as row_num
          FROM full_collection
        ), final_collection as (
          SELECT * FROM partitioned WHERE row_num = 1
        ), like_counts as (
          SELECT
            COUNT(likes.id) as like_count,
            likes.message_id as message_id,
            likes.type as message_type
          FROM likes
          INNER JOIN final_collection
            ON likes.type = final_collection.like_type
            AND likes.message_id = final_collection.id
          GROUP BY
            likes.type, likes.message_id, final_collection.post_date
        ), repost_counts as (
          SELECT
            COUNT(reposts.id) as repost_count,
            reposts.message_id as message_id,
            reposts.type as message_type
          FROM reposts
          INNER JOIN final_collection
            ON reposts.type = final_collection.repost_type
            AND reposts.message_id = final_collection.id
          GROUP BY
            reposts.type, reposts.message_id, final_collection.post_date
        ), all_posts_and_comments as (
          SELECT
            final_collection.*,
            COALESCE(repost_counts.repost_count, 0) as repost_count,
            COALESCE(like_counts.like_count, 0) as like_count,
            (
              (COALESCE(repost_counts.repost_count, 0) * 3) +
              (COALESCE(like_counts.like_count, 0) * 2) +
              (final_collection.comment_count * 1)
            ) as post_rating
          FROM final_collection
          LEFT OUTER JOIN like_counts
            ON like_counts.message_type = final_collection.like_type
            AND like_counts.message_id = final_collection.id
          LEFT OUTER JOIN repost_counts
            ON repost_counts.message_type = final_collection.repost_type
            AND repost_counts.message_id = final_collection.id
        )
        SELECT
          DISTINCT apac.*, DATE(apac.post_date)
        FROM all_posts_and_comments apac
        ORDER BY
          DATE(apac.post_date) DESC,
          apac.post_rating DESC,
          apac.id DESC,
          apac.post_date DESC
      SQL

    results.map do |result|
      {
        id: result["id"],
        text: result["text"],
        created_at: result["created_at"],
        post_type: result["post_type"],
        like_count: result["like_count"],
        repost_count: result["repost_count"],
        comment_count: result["comment_count"],
        post_date: result["post_date"],
        reposted_by: result["reposted_by"],
        reposted_by_username: result["reposted_by_username"],
        user_liked: result["user_liked"],
        user_reposted: result["user_reposted"],
        user_followed: result["user_followed"],
        rating: result["post_rating"],
        replying_to: result["replying_to"].presence&.split(",")&.uniq,
        author: {
          id: result["author_id"],
          username: result["author_username"],
          display_name: result["author_display_name"]
        }
      }
    end
  end

  private

  def bind_id_with_current_user_id_for_query(current_user)
    [
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
  end

  def ensure_session_token!
    self.session_token ||= SecureRandom.urlsafe_base64(32)
  end

  def downcase_email
    self.email = email&.downcase
  end
end
