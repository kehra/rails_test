module Auditable
  extend ActiveSupport::Concern

  included do
    after_create_commit -> { write_audit_log("create", saved_changes.except("created_at", "updated_at")) }
    after_update_commit -> { write_audit_log("update", saved_changes.except("updated_at", "lock_version")) }
    after_destroy_commit -> { write_audit_log("destroy", destroyed_payload) }
  end

  private

  def write_audit_log(action, payload_hash)
    return if payload_hash.blank?

    AuditLog.create!(
      user: Current.user,
      auditable: self,
      action: action,
      payload: payload_hash.to_json
    )
  end

  def destroyed_payload
    attributes.except("created_at", "updated_at")
  end
end
