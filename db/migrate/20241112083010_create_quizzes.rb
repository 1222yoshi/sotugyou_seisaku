class CreateQuizzes < ActiveRecord::Migration[7.1]
  def change
    create_table :quizzes do |t|
      t.string :question
      t.string :image_path
      t.string :quiz_type
      t.integer :quiz_rank

      t.timestamps
    end
  end
end
