class CreateTaskTags < ActiveRecord::Migration[8.1]
  def change
    create_table :task_tags, id: false, primary_key: %i[task_id name] do |t|
      t.integer :task_id, null: false
      t.string :name, null: false
      t.timestamps
    end

    add_index :task_tags, %i[task_id name], unique: true
    add_foreign_key :task_tags, :tasks
  end
end
