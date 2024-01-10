class Follow < ApplicationRecord
  belongs_to :follower, class_name: :User
  belongs_to :followee, class_name: :User

  validate :following_different_user

  private

  def following_different_user
    return if followee_id != follower_id

    errors.add(:base, "Cannot follow self")
  end
end
