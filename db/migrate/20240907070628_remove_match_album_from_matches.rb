class RemoveMatchAlbumFromMatches < ActiveRecord::Migration[7.1]
  def change
    remove_column :matches, :match_album, :integer
  end
end
