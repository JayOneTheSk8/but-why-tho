class AddDisplayNameToUsers < ActiveRecord::Migration[7.1]
  def change
    change_table :users do |t|
      t.string :display_name, null: false
    end
  end
end
