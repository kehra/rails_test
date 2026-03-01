class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.references :assignee, null: true, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.integer :priority, null: false, default: 1
      t.date :due_on
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end
  end
end
