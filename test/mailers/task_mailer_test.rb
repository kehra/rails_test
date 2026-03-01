require "test_helper"

class TaskMailerTest < ActionMailer::TestCase
  test "task_notification" do
    task = tasks(:one)
    notification = notifications(:one)
    notification.update!(
      user: users(:one),
      payload: {
        message: "Alice assigned task \"#{task.title}\".",
        task_id: task.id,
        project_id: task.project_id
      }.to_json
    )

    mail = TaskMailer.with(
      notification_id: notification.id,
      cc: "cc@example.test",
      bcc: "bcc@example.test",
      reply_to: "reply@example.test"
    ).task_notification

    assert_includes mail.subject, "Alice assigned task"
    assert_equal [ users(:one).email ], mail.to
    assert_equal [ "cc@example.test" ], mail.cc
    assert_equal [ "bcc@example.test" ], mail.bcc
    assert_equal [ "reply@example.test" ], mail.reply_to
    assert_equal [ "from@example.com" ], mail.from
    assert_match task.title, mail.body.encoded

    mail.deliver_now
    assert_equal "task_notification", mail["X-TeamHub-Delivery"].to_s
    assert_equal notification.id.to_s, mail["X-TeamHub-Notification-ID"].to_s
  end

  test "parameterized mailer accepts merged params before with" do
    task = tasks(:one)
    notification = notifications(:one)
    notification.update!(
      user: users(:one),
      payload: {
        message: "Alice assigned task \"#{task.title}\".",
        task_id: task.id,
        project_id: task.project_id
      }.to_json
    )

    base_params = { notification_id: notification.id }
    delivery_params = {
      cc: "cc@example.test",
      bcc: "bcc@example.test",
      reply_to: "reply@example.test"
    }

    mail = TaskMailer.with(base_params.merge(delivery_params)).task_notification

    assert_equal [ "cc@example.test" ], mail.cc
    assert_equal [ "bcc@example.test" ], mail.bcc
    assert_equal [ "reply@example.test" ], mail.reply_to
    assert_equal [ users(:one).email ], mail.to
  end

  test "application mailer helper merges parameter sets for parameterized mailers" do
    notification = notifications(:one)
    base_params = { notification_id: notification.id }
    delivery_params = { cc: "cc@example.test", bcc: "bcc@example.test" }

    mail = TaskMailer.with_merged(base_params, delivery_params).task_notification

    assert_equal [ "cc@example.test" ], mail.cc
    assert_equal [ "bcc@example.test" ], mail.bcc
  end

  test "parameterized mailer supports chained with calls via TeamHub patch" do
    notification = notifications(:one)

    mail = TaskMailer.with(notification_id: notification.id)
      .with(cc: "cc@example.test", bcc: "bcc@example.test")
      .task_notification

    assert_equal [ "cc@example.test" ], mail.cc
    assert_equal [ "bcc@example.test" ], mail.bcc
  end
end
