class CreateAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: true, foreign_key: true
      t.string :action
      t.references :auditable, polymorphic: true, null: false
      t.text :payload, null: false

      t.timestamps
    end
  end
end
