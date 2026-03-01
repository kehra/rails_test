class AddPrivateNoteToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :private_note, :text
  end
end
