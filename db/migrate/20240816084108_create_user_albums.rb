class CreateUserAlbums < ActiveRecord::Migration[7.1]
  def change
    create_table :user_albums do |t|
      t.references :user, null: false, foreign_key: true
      t.references :album, null: false, foreign_key: true

      t.timestamps
    end
  end
end
