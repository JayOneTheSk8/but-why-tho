class CreateFollows < ActiveRecord::Migration[7.1]
  def change
    create_table :follows do |t|
      t.references :follower, foreign_key: {to_table: :users}, null: false
      t.references :followee, foreign_key: {to_table: :users}, null: false

      t.index [:follower_id, :followee_id], unique: true
      t.timestamps
    end
  end
end
