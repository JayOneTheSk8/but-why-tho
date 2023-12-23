class CreateAuthors < ActiveRecord::Migration[6.1]
  def change
    create_table :authors do |t|
      t.string :username, null: false
      t.string :email, null: false

      t.index :username, unique: true
      t.index :email, unique: true

      t.timestamps
    end
  end
end
