class CreateContacts < ActiveRecord::Migration[7.1]
  def change
    create_table :contacts do |t|
      t.string :subject, null: false
      t.text :message, null: false

      t.timestamps
    end
  end
end
