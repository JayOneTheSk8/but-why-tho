class CreateLikes < ActiveRecord::Migration[7.1]
  def change
    create_table :likes do |t|
      t.string :type, null: false

      t.references :user, foreign_key: true, null: false
      t.bigint :message_id, null: false

      t.index [:type, :user_id, :message_id], unique: true
      t.index [:type, :message_id]
      t.index [:type, :user_id]

      t.timestamps
    end
  end
end
