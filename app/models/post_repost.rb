class PostRepost < Repost
  belongs_to :user
  belongs_to :post, class_name: :Post, foreign_key: :message_id
end
