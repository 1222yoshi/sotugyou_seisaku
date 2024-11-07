class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: {to_table: :users }
      t.references :source_user, null: false, foreign_key: {to_table: :users }
      t.string :notification_type
      t.boolean :is_read, default: false

      t.timestamps
    end
  end
end
