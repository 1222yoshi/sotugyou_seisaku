class CreateResults < ActiveRecord::Migration[7.1]
  def change
    create_table :results do |t|
      t.references :user, null: false, foreign_key: true
      t.string :quiz_type
      t.integer :rank_score

      t.timestamps
    end
  end
end
