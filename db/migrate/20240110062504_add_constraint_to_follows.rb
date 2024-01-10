class AddConstraintToFollows < ActiveRecord::Migration[7.1]
  def change
    add_check_constraint :follows, "follower_id <> followee_id", name: "different_follwer_and_followee"
  end
end
