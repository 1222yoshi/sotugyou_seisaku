class AddResetEmailToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :reset_email_token, :string, default: nil
    add_column :users, :reset_email_token_expires_at, :datetime, default: nil
    add_column :users, :reset_email_sent_at, :datetime, default: nil
    add_column :users, :access_count_to_reset_email_page, :integer, default: 0
    add_column :users, :reset_email, :string, default: nil

    add_index :users, :reset_email_token
  end
end
