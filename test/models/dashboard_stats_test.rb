require "test_helper"

class DashboardStatsTest < ActiveSupport::TestCase
  test "for returns aggregated counts" do
    stats = DashboardStats.for(users(:one))

    assert_equal 1, stats[:organizations_count]
    assert_equal 1, stats[:projects_count]
    assert_equal 1, stats[:tasks_count]
    assert_equal 0, stats[:unread_notifications_count]
  end

  test "for uses cache" do
    Rails.cache.clear

    first = DashboardStats.for(users(:one))
    Notification.create!(user: users(:one), kind: :generic, payload: { message: "new" }.to_json)
    second = DashboardStats.for(users(:one))

    assert_operator second[:unread_notifications_count], :>=, first[:unread_notifications_count]
  end
end
