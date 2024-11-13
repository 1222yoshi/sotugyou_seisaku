class CreateChoices < ActiveRecord::Migration[7.1]
  def change
    create_table :choices do |t|
      t.references :quiz, null: false, foreign_key: true
      t.string :content
      t.boolean :correct

      t.timestamps
    end
  end
end
