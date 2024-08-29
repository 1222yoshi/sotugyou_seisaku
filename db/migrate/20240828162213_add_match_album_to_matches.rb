class AddMatchAlbumToMatches < ActiveRecord::Migration[7.1]
  def change
    add_column :matches, :match_album, :integer
  end
end
