class AddSessionTokenToUsers < ActiveRecord::Migration[7.1]
  def change
    change_table :users do |t|
      t.string :session_token, null: false
      t.index :session_token, unique: true
    end
  end
end
