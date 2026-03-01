require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "notification model defines turbo stream callback patterns" do
    source = File.read(Rails.root.join("app/models/notification.rb"))

    assert_includes source, "broadcasts_to ->(notification) { [ notification.user, :notification_events ] }"
    assert_includes source, "broadcast_prepend_to"
    assert_includes source, "broadcast_before_to"
    assert_includes source, "broadcast_after_to"
    assert_includes source, "broadcast_append_later_to user, :notification_async_events"
    assert_includes source, "broadcast_update_to"
    assert_includes source, "broadcast_replace_to"
    assert_includes source, "broadcast_remove_to"
  end
end
