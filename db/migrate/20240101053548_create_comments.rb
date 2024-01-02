class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments do |t|
      t.string :text, null: false

      t.references :post, foreign_key: true, null: false
      t.references :author, foreign_key: {to_table: :users}, null: false
      t.bigint :parent_id, index: true

      t.timestamps
    end
  end
end
