require "test_helper"

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    tests ApplicationCable::Connection

    test "connects with signed cookie and identifies current_user" do
      cookies.signed[:cable_user_id] = users(:one).id

      connect

      assert_equal users(:one), connection.current_user
    end

    test "rejects connection without signed cookie" do
      assert_reject_connection { connect }
    end

    test "disconnect emits rails event" do
      cookies.signed[:cable_user_id] = users(:one).id
      events = []
      collector = Object.new
      collector.define_singleton_method(:emit) { |event| events << event }

      Rails.event.subscribe(collector) { |event| event[:name] == "teamhub.cable.disconnect" }

      connect
      disconnect

      assert_equal 1, events.size
      assert_equal "teamhub.cable.disconnect", events.first[:name]
      assert_equal users(:one).id, events.first[:payload][:user_id]
    ensure
      Rails.event.unsubscribe(collector) if collector
    end

    test "statistics returns connection metadata" do
      cookies.signed[:cable_user_id] = users(:one).id

      connect
      connection.define_singleton_method(:subscriptions) { Struct.new(:identifiers).new([ "LifecycleChannel" ]) }

      stats = connection.statistics

      assert_includes stats.keys, :identifier
      assert_includes stats.keys, :started_at
      assert_includes stats.keys, :subscriptions
      assert_includes stats.keys, :request_id
      assert stats[:identifier].present?
      assert_equal [ "LifecycleChannel" ], stats[:subscriptions]
    end

    test "beat transmits ping payload" do
      cookies.signed[:cable_user_id] = users(:one).id
      sent = []

      connect
      connection.define_singleton_method(:transmit) { |message| sent << message }

      connection.beat

      assert_equal 1, sent.size
      assert_equal "ping", sent.first[:type]
      assert_kind_of Integer, sent.first[:message]
    end

    test "server disconnect delegates to remote connections" do
      server = ActionCable.server
      calls = []
      fake_remote = Object.new
      fake_remote.define_singleton_method(:where) do |identifiers|
        calls << [ :where, identifiers ]
        Object.new.tap do |remote_connection|
          remote_connection.define_singleton_method(:disconnect) do |reconnect: true|
            calls << [ :disconnect, reconnect ]
          end
        end
      end

      server.singleton_class.alias_method :__teamhub_original_remote_connections, :remote_connections
      server.singleton_class.define_method(:remote_connections) { fake_remote }

      begin
        server.disconnect(current_user: users(:one))
      ensure
        server.singleton_class.alias_method :remote_connections, :__teamhub_original_remote_connections
        server.singleton_class.remove_method :__teamhub_original_remote_connections
      end

      assert_equal [ :where, { current_user: users(:one) } ], calls[0]
      assert_equal [ :disconnect, true ], calls[1]
    end

    test "connection close transmits disconnect envelope with reconnect flag" do
      cookies.signed[:cable_user_id] = users(:one).id
      sent = []
      fake_websocket = Object.new
      fake_websocket.define_singleton_method(:close) { }

      connect
      connection.define_singleton_method(:transmit) { |message| sent << message }
      connection.instance_variable_set(:@websocket, fake_websocket)

      connection.close(reason: "manual", reconnect: false)

      assert_equal 1, sent.size
      assert_equal "disconnect", sent.first[:type]
      assert_equal "manual", sent.first[:reason]
      assert_equal false, sent.first[:reconnect]
    end

    test "remote connection disconnect can disable reconnect" do
      server = ActionCable.server
      broadcasts = []

      server.singleton_class.alias_method :__teamhub_original_broadcast, :broadcast
      server.singleton_class.define_method(:broadcast) do |stream, payload|
        broadcasts << [ stream, payload ]
      end

      begin
        server.remote_connections.where(current_user: users(:one)).disconnect(reconnect: false)
      ensure
        server.singleton_class.alias_method :broadcast, :__teamhub_original_broadcast
        server.singleton_class.remove_method :__teamhub_original_broadcast
      end

      assert_equal 1, broadcasts.size
      assert_equal "disconnect", broadcasts.first[1][:type]
      assert_equal false, broadcasts.first[1][:reconnect]
    end

    test "send_async delegates to worker pool" do
      cookies.signed[:cable_user_id] = users(:one).id
      calls = []
      fake_pool = Object.new
      fake_pool.define_singleton_method(:async_invoke) do |target, method_name, *args|
        calls << [ target, method_name, args ]
      end

      connect
      connection.define_singleton_method(:worker_pool) { fake_pool }

      connection.send_async(:beat, "extra")

      assert_equal connection, calls.first[0]
      assert_equal :beat, calls.first[1]
      assert_equal [ "extra" ], calls.first[2]
    end

    test "receive and websocket lifecycle callbacks enqueue async handlers" do
      cookies.signed[:cable_user_id] = users(:one).id
      calls = []
      appended = []
      fake_buffer = Object.new
      fake_buffer.define_singleton_method(:append) { |message| appended << message }

      connect
      connection.define_singleton_method(:send_async) do |method_name, *args|
        calls << [ method_name, args ]
      end
      connection.instance_variable_set(:@message_buffer, fake_buffer)

      connection.receive("{\"command\":\"message\"}")
      connection.on_open
      connection.on_message("payload")
      connection.on_close("done", 1000)

      assert_includes calls, [ :dispatch_websocket_message, [ "{\"command\":\"message\"}" ] ]
      assert_includes calls, [ :handle_open, [] ]
      assert_includes calls, [ :handle_close, [] ]
      assert_equal [ "payload" ], appended
    end

    test "dispatch_websocket_message routes decoded payload when socket is alive" do
      cookies.signed[:cable_user_id] = users(:one).id
      handled = []
      fake_websocket = Object.new
      fake_websocket.define_singleton_method(:alive?) { true }

      connect
      connection.instance_variable_set(:@websocket, fake_websocket)
      connection.define_singleton_method(:decode) { |message| { "raw" => message } }
      connection.define_singleton_method(:handle_channel_command) { |payload| handled << payload }

      connection.dispatch_websocket_message("{\"raw\":true}")

      assert_equal [ { "raw" => "{\"raw\":true}" } ], handled
    end

    test "dispatch_websocket_message logs when socket is closed and handle_channel_command delegates" do
      cookies.signed[:cable_user_id] = users(:one).id
      executed = []
      errors = []
      fake_websocket = Object.new
      fake_websocket.define_singleton_method(:alive?) { false }
      fake_logger = Object.new
      fake_logger.define_singleton_method(:error) { |message| errors << message }

      connect
      connection.define_singleton_method(:subscriptions) do
        Object.new.tap do |collector|
          collector.define_singleton_method(:execute_command) { |payload| executed << payload }
        end
      end

      payload = { "command" => "subscribe", "identifier" => "{\"channel\":\"EventsChannel\"}" }
      connection.handle_channel_command(payload)
      connection.instance_variable_set(:@websocket, fake_websocket)
      connection.define_singleton_method(:logger) { fake_logger }
      connection.dispatch_websocket_message("late")

      assert_equal [ payload ], executed
      assert_match "Ignoring message processed after the WebSocket was closed", errors.first
    end

    test "on_error logs websocket failures" do
      cookies.signed[:cable_user_id] = users(:one).id
      errors = []
      fake_logger = Object.new
      fake_logger.define_singleton_method(:error) { |message| errors << message }

      connect
      connection.define_singleton_method(:logger) { fake_logger }

      connection.on_error("boom")

      assert_match "WebSocket error occurred: boom", errors.first
    end

    test "process routes successful and invalid websocket requests" do
      cookies.signed[:cable_user_id] = users(:one).id
      calls = []
      open_websocket = Object.new
      open_websocket.define_singleton_method(:possible?) { true }
      closed_websocket = Object.new
      closed_websocket.define_singleton_method(:possible?) { false }

      connect
      connection.define_singleton_method(:allow_request_origin?) { true }
      connection.define_singleton_method(:respond_to_successful_request) { calls << :success }
      connection.define_singleton_method(:respond_to_invalid_request) { calls << :invalid }

      connection.instance_variable_set(:@websocket, open_websocket)
      connection.process

      connection.instance_variable_set(:@websocket, closed_websocket)
      connection.process

      assert_equal [ :success, :invalid ], calls
    end
  end
end
