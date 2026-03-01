require "test_helper"

class MembershipQueryScopedTest < ActiveSupport::TestCase
  test "query constraints are included in update SQL" do
    statements = []
    subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
      sql = payload[:sql]
      statements << sql if sql.start_with?("UPDATE \"memberships\"")
    end

    membership = Demo::MembershipQueryScoped.find(memberships(:one).id)
    membership.update!(role: :member)

    update_sql = statements.last

    assert_includes update_sql, "\"memberships\".\"organization_id\" = ?"
    assert_includes update_sql, "\"memberships\".\"user_id\" = ?"
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription) if subscription
  end
end
