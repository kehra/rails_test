require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  test "delegated audit entry exposes delegated type helpers" do
    entry = Demo::DelegatedAuditEntry.create!(
      user: users(:one),
      action: "delegated",
      auditable: projects(:one),
      payload: "{}"
    )

    assert entry.project?
    assert_equal projects(:one), entry.project
    assert_equal projects(:one), entry.auditable
  end
end
