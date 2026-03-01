require "test_helper"

class AuditableTest < ActiveSupport::TestCase
  test "project create writes audit log" do
    Current.user = users(:one)

    assert_difference "AuditLog.count", 1 do
      Project.create!(organization: organizations(:one), name: "Audit Project", status: :active)
    end

    log = AuditLog.order(:id).last
    assert_equal "create", log.action
    assert_equal "Project", log.auditable_type
    assert_equal users(:one), log.user
  ensure
    Current.reset
  end

  test "task update writes audit log" do
    Current.user = users(:one)
    task = tasks(:one)

    assert_difference "AuditLog.count", 1 do
      task.update!(title: "Updated by audit")
    end

    log = AuditLog.order(:id).last
    assert_equal "update", log.action
    assert_equal "Task", log.auditable_type
  ensure
    Current.reset
  end

  test "organization destroy writes audit log" do
    Current.user = users(:one)
    org = Organization.create!(name: "Audit Org")
    Membership.create!(organization: org, user: users(:one), role: :owner)

    assert_difference "AuditLog.count", 1 do
      org.destroy!
    end

    log = AuditLog.order(:id).last
    assert_equal "destroy", log.action
    assert_equal "Organization", log.auditable_type
  ensure
    Current.reset
  end
end
