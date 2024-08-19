class CreateAlbums < ActiveRecord::Migration[7.1]
  def change
    create_table :albums do |t|
      t.string :artist_name
      t.string :album_name
      t.string :itunes_album_id
      t.string :artwork_url

      t.timestamps
    end
  end
end
