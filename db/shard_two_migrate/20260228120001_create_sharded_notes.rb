class CreateShardedNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :sharded_notes do |t|
      t.string :external_key, null: false
      t.text :body, null: false
      t.timestamps
    end

    add_index :sharded_notes, :external_key, unique: true
  end
end
