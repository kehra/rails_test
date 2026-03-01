class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :kind, null: false, default: 0
      t.datetime :read_at
      t.text :payload, null: false

      t.timestamps
    end
  end
end
