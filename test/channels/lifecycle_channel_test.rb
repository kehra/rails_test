require "test_helper"

class LifecycleChannelTest < ActionCable::Channel::TestCase
  test "subscribes with explicit allow and starts named and model streams" do
    stub_connection current_user: users(:one)

    subscribe allow: true

    assert subscription.confirmed?
    assert_has_stream "teamhub:lifecycle:#{users(:one).id}"
    assert_has_stream "teamhub:lifecycle:decoded:#{users(:one).id}"
    assert_has_stream_for users(:one)
  end

  test "rejects when allow param is not set" do
    stub_connection current_user: users(:one)

    subscribe allow: false

    assert subscription.rejected?
  end

  test "stop actions and unsubscribe lifecycle are wired" do
    stub_connection current_user: users(:one)
    subscribe allow: true

    perform :stop_named
    assert_equal "stopped_named", transmissions.last["event"]
    assert_has_no_stream "teamhub:lifecycle:#{users(:one).id}"

    perform :stop_user
    assert_equal "stopped_user", transmissions.last["event"]
    assert_has_no_stream_for users(:one)

    perform :stop_decoded
    assert_equal "stopped_decoded", transmissions.last["event"]
    assert_has_no_stream "teamhub:lifecycle:decoded:#{users(:one).id}"

    subscribe allow: true

    unsubscribe

    assert_includes LifecycleChannel.last_unsubscribed_streams, "teamhub:lifecycle:decoded:#{users(:one).id}"
    assert_empty subscription.streams
  end

  test "explicit defer subscription confirmation api can be invoked" do
    stub_connection current_user: users(:one)
    subscribe allow: true

    perform :delay_confirmation

    assert_equal "delayed_confirmation", transmissions.last["event"]
  end

  test "direct subscribe api exposes channel state methods" do
    stub_connection current_user: users(:one)
    identifier = { channel: "LifecycleChannel", allow: true }.to_json

    channel = LifecycleChannel.new(connection, identifier, { "allow" => true })
    channel.subscribe_to_channel

    assert_equal true, channel.send(:defer_subscription_confirmation?)
    assert_nil channel.send(:subscription_confirmation_sent?)
  end

  test "direct perform and unsubscribe apis work on a subscribed channel" do
    stub_connection current_user: users(:one)
    subscribe allow: true

    subscription.perform_action({ "action" => "stop_named" })

    assert_equal "stopped_named", transmissions.last["event"]

    subscription.unsubscribe_from_channel

    assert subscription.unsubscribed?
    assert_includes LifecycleChannel.last_unsubscribed_streams, "teamhub:lifecycle:decoded:#{users(:one).id}"
  end

  test "rejected channel exposes rejection state" do
    stub_connection current_user: users(:one)
    identifier = { channel: "LifecycleChannel", allow: false }.to_json

    channel = LifecycleChannel.new(connection, identifier, { "allow" => false })
    channel.subscribe_to_channel

    assert_equal true, channel.send(:subscription_rejected?)
    assert_nil channel.send(:subscription_confirmation_sent?)
  end

  test "channel declares periodic timer and stop APIs" do
    source = File.read(Rails.root.join("app/channels/lifecycle_channel.rb"))

    assert_equal 1, LifecycleChannel.periodic_timers.size
    assert_includes source, "defer_subscription_confirmation!"
    assert_includes source, "periodically :emit_heartbeat"
    assert_includes source, "coder: ActiveSupport::JSON"
    assert_includes source, "stop_stream_from"
    assert_includes source, "stop_stream_for"
    assert_includes source, "stop_all_streams"
    assert_includes source, "reject"
  end
end
