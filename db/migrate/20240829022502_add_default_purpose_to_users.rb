class AddDefaultPurposeToUsers < ActiveRecord::Migration[7.1]
  def change
    change_column_default :users, :purpose, 'hobby'
  end
end
