class AddTypeToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :type, :string
    add_index :notifications, :type
  end
end
