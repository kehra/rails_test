require "test_helper"

class ActionCableServerApiTest < ActiveSupport::TestCase
  test "server exposes runtime components and connection identifiers" do
    config = ActionCable.server.config.dup
    fake_adapter = Class.new do
      attr_reader :server

      def initialize(server)
        @server = server
      end

      def shutdown
      end
    end

    config.singleton_class.define_method(:pubsub_adapter) { fake_adapter }

    server = ActionCable::Server::Base.new(config: config)
    remote = server.remote_connections.where(current_user: users(:one))

    assert_instance_of ActionCable::RemoteConnections, server.remote_connections
    assert_kind_of ActionCable::Connection::StreamEventLoop, server.event_loop
    assert_kind_of ActionCable::Server::Worker, server.worker_pool
    assert_instance_of fake_adapter, server.pubsub
    assert_includes server.connection_identifiers, :current_user
    assert_equal Set[:current_user], remote.identifiers
    assert_equal users(:one), remote.instance_variable_get(:@current_user)
  end

  test "server restart closes connections and halts worker services" do
    server = ActionCable::Server::Base.new(config: ActionCable.server.config)
    calls = []
    fake_connection = Object.new
    fake_connection.define_singleton_method(:close) do |reason:, reconnect: true|
      calls << [ :close, reason, reconnect ]
    end
    fake_worker = Object.new
    fake_worker.define_singleton_method(:halt) { calls << [ :halt ] }
    fake_pubsub = Object.new
    fake_pubsub.define_singleton_method(:shutdown) { calls << [ :shutdown ] }

    server.define_singleton_method(:connections) { [ fake_connection ] }
    server.instance_variable_set(:@worker_pool, fake_worker)
    server.instance_variable_set(:@pubsub, fake_pubsub)

    server.restart

    assert_equal :close, calls[0][0]
    assert_equal ActionCable::INTERNAL[:disconnect_reasons][:server_restart], calls[0][1]
    assert_equal [ :halt ], calls[1]
    assert_equal [ :shutdown ], calls[2]
    assert_nil server.instance_variable_get(:@worker_pool)
    assert_nil server.instance_variable_get(:@pubsub)
  end

  test "server call returns health check response on health path" do
    response = ActionCable.server.call("PATH_INFO" => ActionCable.server.config.health_check_path)

    assert_equal 200, response[0]
  end

  test "server call routes websocket requests through connection class" do
    config = ActionCable.server.config.dup
    fake_connection_class = Class.new do
      def initialize(_server, env)
        @env = env
      end

      def process
        [ 101, { "X-ActionCable-Path" => @env["PATH_INFO"] }, [ "switched" ] ]
      end
    end

    config.singleton_class.define_method(:health_check_path) { "/_teamhub_health" }
    config.singleton_class.define_method(:connection_class) { -> { fake_connection_class } }

    server = ActionCable::Server::Base.new(config: config)
    setup_calls = []
    server.define_singleton_method(:setup_heartbeat_timer) { setup_calls << :setup }

    response = server.call("PATH_INFO" => "/cable")

    assert_equal [ :setup ], setup_calls
    assert_equal 101, response[0]
    assert_equal "/cable", response[1]["X-ActionCable-Path"]
  end
end
