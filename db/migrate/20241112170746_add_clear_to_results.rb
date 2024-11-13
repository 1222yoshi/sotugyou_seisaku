class AddClearToResults < ActiveRecord::Migration[7.1]
  def change
    add_column :results, :clear, :boolean
  end
end
