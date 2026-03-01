class Demo::DelegatedAuditEntry < ApplicationRecord
  self.table_name = "audit_logs"

  belongs_to :user, optional: true

  delegated_type :auditable,
    types: %w[Project Task],
    foreign_key: :auditable_id,
    foreign_type: :auditable_type
end
