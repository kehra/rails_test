require "test_helper"

class AdvancedMailerTest < ActionMailer::TestCase
  include ActiveJob::TestHelper

  test "advanced mailer covers callbacks defaults headers attachments and multipart block" do
    AdvancedMailer.callback_log = []
    delivery = AdvancedMailer.with(
      recipient: "reader@example.test",
      recipient_name: "Alice",
      project: projects(:one),
      trace: "trace-123",
      label: "daily"
    ).digest_report

    assert_not_predicate delivery, :processed?

    mail = delivery.message

    assert_predicate delivery, :processed?
    assert_equal [ "reader@example.test" ], mail.to
    assert_equal "TeamHub Robot <robot@example.test>", mail[:from].to_s
    assert_equal "[TeamHub] TeamHub digest", mail.subject
    assert_equal "trace-123", mail["X-Trace-Token"].to_s
    assert_equal "advanced-mailer", mail["X-Workflow"].to_s
    assert_equal "ran", mail["X-After-Action"].to_s
    assert mail.multipart?
    assert_equal [ "pixel.txt", "summary.txt" ], mail.attachments.map(&:filename).map(&:to_s).sort
    assert_equal "mailer.example.test", AdvancedMailer.new.default_url_options[:host]
    assert_equal [ :around_action_before, :around_action_after ], AdvancedMailer.callback_log

    delivery.deliver_now!

    assert_equal [ :around_action_before, :around_action_after, :around_deliver_before, :around_deliver_after ], AdvancedMailer.callback_log
  end

  test "message delivery queue apis enqueue and batch enqueue" do
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs

    one = AdvancedMailer.with(recipient: "one@example.test", project: projects(:one)).digest_report
    two = AdvancedMailer.with(recipient: "two@example.test", project: projects(:one)).digest_report

    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      one.deliver_later!
    end

    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      two.deliver_later
    end

    three = AdvancedMailer.with(recipient: "three@example.test", project: projects(:one)).digest_report
    four = AdvancedMailer.with(recipient: "four@example.test", project: projects(:one)).digest_report

    assert_enqueued_jobs 2, only: ActionMailer::MailDeliveryJob do
      ActionMailer.deliver_all_later(three, four)
    end

    five = AdvancedMailer.with(recipient: "five@example.test", project: projects(:one)).digest_report
    six = AdvancedMailer.with(recipient: "six@example.test", project: projects(:one)).digest_report

    assert_enqueued_jobs 2, only: ActionMailer::MailDeliveryJob do
      ActionMailer.deliver_all_later!(five, six)
    end
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
  end

  test "application mailer helper can merge parameterized mailer params" do
    delivery = AdvancedMailer.with_merged(
      { recipient: "merge@example.test", project: projects(:one) },
      { trace: "trace-merge", label: "weekly" }
    ).digest_report

    mail = delivery.message

    assert_equal [ "merge@example.test" ], mail.to
    assert_equal "trace-merge", mail["X-Trace-Token"].to_s
  end

  test "observer and interceptor registries can be registered and unregistered" do
    AdvancedMailerObserver.delivered_subjects = []
    AdvancedMailer.register_observers("AdvancedMailerObserver")
    AdvancedMailer.register_interceptors(:advanced_mailer_runtime_interceptor)

    mail = AdvancedMailer.with(recipient: "registry@example.test", project: projects(:one)).digest_report.deliver_now

    assert_equal "registered", mail["X-Registry-Interceptor"].to_s
    assert_includes AdvancedMailerObserver.delivered_subjects, mail.subject
  ensure
    AdvancedMailer.unregister_observers("AdvancedMailerObserver")
    AdvancedMailer.unregister_interceptors(:advanced_mailer_runtime_interceptor)
  end
end
