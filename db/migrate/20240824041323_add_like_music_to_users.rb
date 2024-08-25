class AddLikeMusicToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :like_music, :text
  end
end
