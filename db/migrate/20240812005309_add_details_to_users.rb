class AddDetailsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :birthdate, :date
    add_column :users, :gender, :string
    add_column :users, :purpose, :string
    add_column :users, :introduction, :text
    add_column :users, :profile_image, :string
    add_column :users, :x_link, :string
    add_column :users, :instagram_link, :string
    add_column :users, :youtube_link, :string
    add_column :users, :custom_link, :string
  end
end
