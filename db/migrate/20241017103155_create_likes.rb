class CreateLikes < ActiveRecord::Migration[7.1]
  def change
    create_table :likes do |t|
      t.references :like_user, null: false, foreign_key: {to_table: :users }
      t.references :liked_user, null: false, foreign_key: {to_table: :users }

      t.timestamps
    end
  end
end
