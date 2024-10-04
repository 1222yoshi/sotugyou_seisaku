class AddOrderNumberToUserAlbums < ActiveRecord::Migration[7.1]
  def change
    add_column :user_albums, :order_number, :integer
  end
end
