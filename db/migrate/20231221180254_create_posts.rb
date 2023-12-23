class CreatePosts < ActiveRecord::Migration[6.1]
  def change
    create_table :posts do |t|
      t.string :text, null: false
      t.references :author, foreign_key: true, null: false
      t.timestamps
    end

    add_check_constraint :posts, "length(text) <= 200", name: "text_maximum_length"
  end
end
