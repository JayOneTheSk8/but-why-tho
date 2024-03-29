class Post < ApplicationRecord
  include QuestionValidation

  belongs_to :author, class_name: :User

  has_many(
    :comments,
    -> { where(parent_id: nil) },
    dependent: :destroy
  )
  has_many(
    :likes,
    class_name: :PostLike,
    foreign_key: :message_id,
    dependent: :destroy
  )
  has_many(
    :reposts,
    class_name: :PostRepost,
    foreign_key: :message_id,
    dependent: :destroy
  )

  def self.search_posts(search_text, current_user: nil, limit: 100)
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

    results =
      ActiveRecord::Base.connection.select_all(<<~SQL.squish, "Posts Search", binds).to_a
        WITH current_user_reposts as (
          SELECT
            reposts.id as repost_id,
            reposts.created_at as reposted_at,
            reposts.type as repost_type,
            reposts.message_id as message_id
          FROM reposts
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
        ), found_posts as (
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
          WHERE posts.text ILIKE $2
          GROUP BY
            posts.id,
            post_authors.id,
            current_user_likes.like_id,
            current_user_reposts.repost_id,
            current_user_subscriptions.follow_id
        ), like_counts as (
          SELECT
            COUNT(likes.id) as like_count,
            likes.message_id as message_id,
            likes.type as message_type
          FROM likes
          INNER JOIN found_posts
            ON likes.type = found_posts.like_type
            AND likes.message_id = found_posts.id
          GROUP BY
            likes.type, likes.message_id
        ), repost_counts as (
          SELECT
            COUNT(reposts.id) as repost_count,
            reposts.message_id as message_id,
            reposts.type as message_type
          FROM reposts
          INNER JOIN found_posts
            ON reposts.type = found_posts.repost_type
            AND reposts.message_id = found_posts.id
          GROUP BY
            reposts.type, reposts.message_id
        )
        SELECT
          found_posts.*,
          COALESCE(repost_counts.repost_count, 0) as repost_count,
          COALESCE(like_counts.like_count, 0) as like_count,
          (
            (COALESCE(repost_counts.repost_count, 0) * 3) +
            (COALESCE(like_counts.like_count, 0) * 2) +
            (found_posts.comment_count * 1)
          ) as post_rating
        FROM found_posts
        LEFT OUTER JOIN like_counts
          ON like_counts.message_type = found_posts.like_type
          AND like_counts.message_id = found_posts.id
        LEFT OUTER JOIN repost_counts
          ON repost_counts.message_type = found_posts.repost_type
          AND repost_counts.message_id = found_posts.id
        ORDER BY
          post_rating DESC,
          found_posts.id DESC
        LIMIT $3
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

  def self.popular_posts_and_comments(current_user: nil)
    binds = [
      ActiveRecord::Relation::QueryAttribute.new(
        "current_user_id",
        current_user&.id || 0,
        ActiveRecord::Type::Integer.new
      )
    ]

    results =
      ActiveRecord::Base.connection.select_all(<<~SQL.squish, "Popular Posts", binds).to_a
        WITH current_user_reposts as (
          SELECT
            reposts.id as repost_id,
            reposts.created_at as reposted_at,
            reposts.type as repost_type,
            reposts.message_id as message_id
          FROM reposts
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
        ), all_posts as (
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
          GROUP BY
            posts.id,
            post_authors.id,
            current_user_likes.like_id,
            current_user_reposts.repost_id,
            current_user_subscriptions.follow_id
        ), all_comments as (
          SELECT
            comments.id as id,
            comments.text as text,
            comments.created_at as created_at,
            comment_authors.id as author_id,
            comment_authors.username as author_username,
            comment_authors.display_name as author_display_name,
            comments.created_at as post_date,
            'CommentRepost' as post_type,
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
          SELECT * FROM all_posts
          UNION ALL
          SELECT * FROM all_comments
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
        ), all_posts_and_comments as (
          SELECT
            merged.*,
            COALESCE(repost_counts.repost_count, 0) as repost_count,
            COALESCE(like_counts.like_count, 0) as like_count,
            (
              (COALESCE(repost_counts.repost_count, 0) * 3) +
              (COALESCE(like_counts.like_count, 0) * 2) +
              (merged.comment_count * 1)
            ) as post_rating
          FROM merged
          LEFT OUTER JOIN like_counts
            ON like_counts.message_type = merged.like_type
            AND like_counts.message_id = merged.id
          LEFT OUTER JOIN repost_counts
            ON repost_counts.message_type = merged.repost_type
            AND repost_counts.message_id = merged.id
        )
        SELECT apac.*
        FROM all_posts_and_comments apac
        WHERE apac.post_type != 'CommentRepost' OR apac.repost_count > 4
        ORDER BY
          DATE(apac.post_date) DESC,
          apac.post_rating DESC,
          apac.id DESC
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

  def get_data(current_user: nil)
    binds = [
      ActiveRecord::Relation::QueryAttribute.new(
        "post_id",
        id,
        ActiveRecord::Type::Integer.new
      ),
      ActiveRecord::Relation::QueryAttribute.new(
        "current_user_id",
        current_user&.id || 0,
        ActiveRecord::Type::Integer.new
      )
    ]

    sql_results =
      ActiveRecord::Base.connection.select_all(<<~SQL.squish, "Post Data", binds).to_a
        WITH current_user_reposts as (
          SELECT
            reposts.id as repost_id,
            reposts.created_at as reposted_at,
            reposts.type as repost_type,
            reposts.message_id as message_id,
            reposter.display_name as reposter_display_name
          FROM reposts
          INNER JOIN users reposter
            ON reposter.id = reposts.user_id
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
        ), post_data as (
          SELECT
            posts.id as id,
            posts.text as text,
            posts.created_at as created_at,
            post_authors.id as author_id,
            post_authors.username as author_username,
            post_authors.display_name as author_display_name,
            'PostRepost' as repost_type,
            'PostLike' as like_type,
            'Post' as show_type,
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
          WHERE posts.id = $1
          GROUP BY
            posts.id,
            post_authors.id,
            current_user_likes.like_id,
            current_user_reposts.repost_id,
            current_user_subscriptions.follow_id
        ), post_comment_data as (
          SELECT
            comments.id as id,
            comments.text as text,
            comments.created_at as created_at,
            comment_authors.id as author_id,
            comment_authors.username as author_username,
            comment_authors.display_name as author_display_name,
            'CommentRepost' as repost_type,
            'CommentLike' as like_type,
            'Comment' as show_type,
            comment_post_author.username as replying_to,
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
          WHERE comments.post_id = $1 AND comments.parent_id IS NULL
          GROUP BY
            comments.id,
            comment_authors.id,
            comment_post_author.username,
            current_user_likes.like_id,
            current_user_reposts.repost_id,
            current_user_subscriptions.follow_id
        ), merged as (
          SELECT * FROM post_data
          UNION ALL
          SELECT * FROM post_comment_data
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
        ORDER BY merged.created_at DESC
      SQL

    results = {
      comments: []
    }

    sql_results.each do |result|
      case result["show_type"].to_sym
      when :Post
        results.merge!(map_sql_to_message(result))
      when :Comment
        results[:comments] << map_sql_to_message(result)
      end
    end

    results
  end
end
