class CreateMatches < ActiveRecord::Migration[7.1]
  def change
    create_table :matches do |t|
      t.references :user, null: false, foreign_key: true
      t.references :other_user, null: false, foreign_key: { to_table: :users }
      t.integer :score, null: false

      t.timestamps
    end

    add_index :matches, %i[user_id other_user_id], unique: true
  end
end
