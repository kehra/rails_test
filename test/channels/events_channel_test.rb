require "test_helper"

class EventsChannelTest < ActionCable::Channel::TestCase
  test "subscribes and streams for current user via stream_or_reject_for" do
    stub_connection current_user: users(:one)

    subscribe

    assert subscription.confirmed?
    assert_has_stream_for users(:one)
  end

  test "rejects subscription when current_user is missing" do
    stub_connection current_user: nil

    subscribe

    assert subscription.rejected?
  end

  test "perform ping transmits pong payload" do
    stub_connection current_user: users(:one)
    subscribe

    perform :ping

    assert_equal "pong", transmissions.last["event"]
    assert_equal "ok", transmissions.last["received"]
  end
end
