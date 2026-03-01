require "test_helper"
require "action_mailbox/test_helper"

class ActionMailboxFeatureTest < ActiveSupport::TestCase
  include ActionMailbox::TestHelper

  setup do
    WorkflowMailbox.callback_log = []
  end

  test "application mailbox declares expanded routing patterns" do
    source = File.read(Rails.root.join("app/mailboxes/application_mailbox.rb"))

    assert_includes source, "routing VipSupportRoute.new => :support"
    assert_includes source, "routing \"workflow@example.test\" => :workflow"
    assert_includes source, "routing \"rescue@example.test\" => :rescue_demo"
  end

  test "workflow mailbox receive runs callbacks and marks inbound email delivered" do
    inbound_email = create_inbound_email_from_mail(
      status: :pending,
      to: "workflow@example.test",
      from: users(:one).email,
      subject: "Workflow demo",
      body: "Created in mailbox"
    )

    WorkflowMailbox.receive(inbound_email)
    inbound_email.reload

    assert_equal [ :before, :around_before, :process, :after, :around_after ], WorkflowMailbox.callback_log
    assert_predicate inbound_email, :delivered?
    assert_predicate WorkflowMailbox.new(inbound_email), :finished_processing?
  end

  test "custom matcher route resolves to support mailbox" do
    inbound_email = create_inbound_email_from_mail(
      status: :pending,
      to: "vip-help@example.test",
      from: users(:one).email,
      subject: "VIP support",
      body: "Need help"
    )

    assert_equal SupportMailbox, ApplicationMailbox.mailbox_for(inbound_email)
  end

  test "tasks mailbox routes inbound email from helper and creates task" do
    inbound_email = nil

    assert_difference("Task.count", 1) do
      inbound_email = receive_inbound_email_from_mail(
        to: "tasks+#{projects(:one).id}@example.test",
        from: users(:one).email,
        subject: "Mailbox task",
        body: "Created via helper"
      )
    end

    assert_predicate inbound_email.reload, :delivered?
    assert_equal "Mailbox task", Task.order(:id).last.title
    assert_match "Created via helper", Task.order(:id).last.description
  end

  test "support and backstop mailboxes use bounce delivery apis" do
    support_inbound = create_inbound_email_from_mail(
      status: :pending,
      to: "help@example.test",
      from: "guest@example.test",
      subject: "Need help",
      body: "Body"
    )
    backstop_inbound = create_inbound_email_from_mail(
      status: :pending,
      to: "nobody@example.test",
      from: "guest@example.test",
      subject: "Unknown",
      body: "Body"
    )
    calls = []
    fake_proxy = Object.new
    fake_proxy.define_singleton_method(:support_bounce) do
      Object.new.tap do |delivery|
        delivery.define_singleton_method(:deliver_later) { calls << :deliver_later }
      end
    end
    fake_proxy.define_singleton_method(:backstop_bounce) do
      Object.new.tap do |delivery|
        delivery.define_singleton_method(:deliver_now) { calls << :deliver_now }
      end
    end
    InboundMailboxMailer.singleton_class.alias_method :__teamhub_original_with, :with
    InboundMailboxMailer.singleton_class.define_method(:with) do |params|
      calls << [ :with, params ]
      fake_proxy
    end

    begin
      SupportMailbox.receive(support_inbound)
      BackstopMailbox.receive(backstop_inbound)
    ensure
      InboundMailboxMailer.singleton_class.alias_method :with, :__teamhub_original_with
      InboundMailboxMailer.singleton_class.remove_method :__teamhub_original_with
    end

    assert_predicate support_inbound.reload, :bounced?
    assert_predicate backstop_inbound.reload, :bounced?
    assert_includes calls, :deliver_later
    assert_includes calls, :deliver_now
  end

  test "rescue mailbox marks inbound email bounced" do
    inbound_email = create_inbound_email_from_mail(
      status: :pending,
      to: "rescue@example.test",
      from: users(:one).email,
      subject: "Rescue demo",
      body: "Will bounce"
    )

    RescueDemoMailbox.receive(inbound_email)

    assert_predicate inbound_email.reload, :bounced?
    assert_predicate inbound_email, :processed?
  end

  test "test helper variants and mail extension helpers are callable" do
    user_email = users(:one).email
    fixture_email = create_inbound_email_from_fixture("inbound_mailbox_sample.eml", status: :pending)
    source_email = create_inbound_email_from_source(<<~MAIL, status: :pending)
      From: Source Sender <source-sender@example.test>
      To: workflow@example.test
      Subject: Source Subject
      Message-ID: <source-mailbox@example.test>

      Source body.
    MAIL
    mail_email = create_inbound_email_from_mail(status: :pending) do
      to "Workflow <workflow@example.test>"
      from "Alice <#{user_email}>"
      cc "CC <cc@example.test>"
      bcc "BCC <bcc@example.test>"
      reply_to "Reply <reply@example.test>"
      subject "Composite mailbox"

      text_part do
        body "Plain body"
      end

      html_part do
        body "<p>HTML body</p>"
      end
    end

    assert_match "Fixture body from eml helper", fixture_email.source
    assert_equal "Fixture Subject", fixture_email.mail.subject
    assert_equal "source-sender@example.test", source_email.mail.from_address.address
    assert_equal user_email, mail_email.mail.from_address.address
    assert_equal "reply@example.test", mail_email.mail.reply_to_address.address
    assert_equal "workflow@example.test", mail_email.mail.to_addresses.first.address
    assert_equal "cc@example.test", mail_email.mail.cc_addresses.first.address
    assert_equal "bcc@example.test", mail_email.mail.bcc_addresses.first.address
    assert_equal 3, mail_email.mail.recipients_addresses.size
    assert_equal 3, mail_email.mail.recipients.size
    assert_equal false, mail_email.processed?
  end

  test "route_later route incinerate_later and incinerate are callable" do
    inbound_email = create_inbound_email_from_mail(
      status: :pending,
      to: "workflow@example.test",
      from: users(:one).email,
      subject: "Lifecycle",
      body: "Lifecycle body"
    )
    routing_calls = []
    incineration_calls = []
    original_incinerate_after = ActionMailbox.incinerate_after

    ActionMailbox::RoutingJob.singleton_class.alias_method :__teamhub_original_perform_later, :perform_later
    ActionMailbox::RoutingJob.singleton_class.define_method(:perform_later) do |record|
      routing_calls << record
    end
    ActionMailbox::IncinerationJob.singleton_class.alias_method :__teamhub_original_schedule, :schedule
    ActionMailbox::IncinerationJob.singleton_class.define_method(:schedule) do |record|
      incineration_calls << record
    end

    begin
      inbound_email.route_later
      assert_equal [ inbound_email ], routing_calls
      assert_equal WorkflowMailbox, ApplicationMailbox.mailbox_for(inbound_email)

      inbound_email.route
      inbound_email.reload
      assert_predicate inbound_email, :delivered?

      incineration_calls.clear
      inbound_email.incinerate_later
      assert_equal [ inbound_email ], incineration_calls

      ActionMailbox.incinerate_after = 1.day
      inbound_email.update_columns(status: :delivered, updated_at: 3.days.ago)

      assert_difference("ActionMailbox::InboundEmail.count", -1) do
        inbound_email.incinerate
      end
    ensure
      ActionMailbox::RoutingJob.singleton_class.alias_method :perform_later, :__teamhub_original_perform_later
      ActionMailbox::RoutingJob.singleton_class.remove_method :__teamhub_original_perform_later
      ActionMailbox::IncinerationJob.singleton_class.alias_method :schedule, :__teamhub_original_schedule
      ActionMailbox::IncinerationJob.singleton_class.remove_method :__teamhub_original_schedule
      ActionMailbox.incinerate_after = original_incinerate_after
    end
  end

  test "receive helper from fixture and source routes immediately" do
    fixture_email = receive_inbound_email_from_fixture("inbound_mailbox_sample.eml")
    source_email = receive_inbound_email_from_source(<<~MAIL)
      From: Routed Source <routed-source@example.test>
      To: rescue@example.test
      Subject: Routed Source
      Message-ID: <routed-source@example.test>

      Routed source body.
    MAIL

    assert_predicate fixture_email.reload, :delivered?
    assert_predicate source_email.reload, :bounced?
  end
end
