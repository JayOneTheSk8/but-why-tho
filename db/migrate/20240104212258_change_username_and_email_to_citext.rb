class ChangeUsernameAndEmailToCitext < ActiveRecord::Migration[7.1]
  def up
    change_column :users, :email, :citext, null: false
    change_column :users, :username, :citext, null: false
  end

  def down
    change_column :users, :email, :string, null: false
    change_column :users, :username, :string, null: false
  end
end
