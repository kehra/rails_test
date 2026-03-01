require "test_helper"
require "action_mailbox/relayer"
require "action_mailbox/test_helper"

class ActionMailboxPublicApiTest < ActiveSupport::TestCase
  include ActionMailbox::TestHelper

  test "action mailbox accessors are callable" do
    old_values = {
      ingress: ActionMailbox.ingress,
      logger: ActionMailbox.logger,
      incinerate: ActionMailbox.incinerate,
      incinerate_after: ActionMailbox.incinerate_after,
      queues: ActionMailbox.queues,
      storage_service: ActionMailbox.storage_service
    }

    ActionMailbox.ingress = :relay
    ActionMailbox.logger = Rails.logger
    ActionMailbox.incinerate = false
    ActionMailbox.incinerate_after = 1.day
    ActionMailbox.queues = { routing: :default }
    ActionMailbox.storage_service = :local

    assert_equal :relay, ActionMailbox.ingress
    assert_equal false, ActionMailbox.incinerate
    assert_equal 1.day, ActionMailbox.incinerate_after
    assert_equal({ routing: :default }, ActionMailbox.queues)
    assert_equal :local, ActionMailbox.storage_service
    assert_not_nil ActionMailbox.logger
  ensure
    ActionMailbox.ingress = old_values[:ingress]
    ActionMailbox.logger = old_values[:logger]
    ActionMailbox.incinerate = old_values[:incinerate]
    ActionMailbox.incinerate_after = old_values[:incinerate_after]
    ActionMailbox.queues = old_values[:queues]
    ActionMailbox.storage_service = old_values[:storage_service]
  end

  test "relayer relay and result predicates are callable" do
    relayer = ActionMailbox::Relayer.new(
      url: "https://example.test/rails/action_mailbox/relay/inbound_emails",
      password: "secret"
    )
    ok_response = Net::HTTPOK.new("1.1", "200", "OK")
    unauthorized_response = Net::HTTPUnauthorized.new("1.1", "401", "Unauthorized")

    relayer.define_singleton_method(:post) { |_source| ok_response }
    success = relayer.relay("RAW EMAIL")

    assert_predicate success, :success?
    assert_not_predicate success, :failure?
    assert_equal "2.0.0", success.status_code

    relayer.define_singleton_method(:post) { |_source| unauthorized_response }
    unauthorized = relayer.relay("RAW EMAIL")

    assert_predicate unauthorized, :failure?
    assert_predicate unauthorized, :transient_failure?
    assert_not_predicate unauthorized, :permanent_failure?

    permanent = ActionMailbox::Relayer::Result.new("5.1.1", "Permanent")

    assert_predicate permanent, :failure?
    assert_predicate permanent, :permanent_failure?
  end

  test "router and route apis are callable directly" do
    inbound_email = create_inbound_email_from_mail(
      status: :pending,
      to: "workflow@example.test",
      from: users(:one).email,
      subject: "Router direct",
      body: "Router body"
    )
    router = ActionMailbox::Router.new
    route = ActionMailbox::Router::Route.new(/^workflow@/i, to: :workflow)

    router.add_route "help@example.test", to: :support
    router.add_routes(
      "workflow@example.test" => :workflow,
      :all => :backstop
    )

    assert route.match?(inbound_email)
    assert_equal WorkflowMailbox, route.mailbox_class
    assert_equal WorkflowMailbox, router.mailbox_for(inbound_email)

    router.route(inbound_email)
    inbound_email.reload

    assert_predicate inbound_email, :delivered?
  end

  test "router raises routing error without matching route" do
    inbound_email = create_inbound_email_from_mail(
      status: :pending,
      to: "nobody@example.test",
      from: users(:one).email,
      subject: "No route",
      body: "Router body"
    )
    router = ActionMailbox::Router.new

    assert_raises(ActionMailbox::Router::RoutingError) { router.route(inbound_email) }
    assert_predicate inbound_email.reload, :bounced?
  end

  test "inbound email instrumentation payload and process notifications are emitted" do
    inbound_email = create_inbound_email_from_mail(
      status: :pending,
      to: "workflow@example.test",
      from: users(:one).email,
      subject: "Instrumentation",
      body: "Track me"
    )
    events = []
    callback = ->(*args) { events << ActiveSupport::Notifications::Event.new(*args) }

    payload = inbound_email.instrumentation_payload
    subscription = ActiveSupport::Notifications.subscribe("process.action_mailbox", callback)

    WorkflowMailbox.receive(inbound_email)
  ensure
    ActiveSupport::Notifications.unsubscribe(subscription) if subscription

    assert_equal inbound_email.id, payload[:id]
    assert_equal inbound_email.message_id, payload[:message_id]
    assert_equal "pending", payload[:status]
    assert_equal 1, events.size
    assert_equal "process.action_mailbox", events.first.name
    assert_equal inbound_email.id, events.first.payload[:inbound_email][:id]
    assert_equal WorkflowMailbox, events.first.payload[:mailbox].class
  end
end
