class CreateAreas < ActiveRecord::Migration[7.1]
  def change
    create_table :areas do |t|
      t.string :name, null: false
      t.string :region

      t.timestamps
    end
  end
end
