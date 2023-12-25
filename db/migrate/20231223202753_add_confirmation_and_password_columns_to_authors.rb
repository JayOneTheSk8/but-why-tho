class AddConfirmationAndPasswordColumnsToAuthors < ActiveRecord::Migration[7.1]
  def change
    change_table :authors, bulk: true do |t|
      t.datetime :confirmed_at
      t.string :password_digest, null: false
    end
  end
end
