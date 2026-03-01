require "test_helper"

class NotificationsChannelTest < ActionCable::Channel::TestCase
  test "subscribes and streams for current user" do
    stub_connection current_user: users(:one)

    subscribe

    assert subscription.confirmed?
    assert_has_stream_for users(:one)
  end
end
