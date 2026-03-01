require "test_helper"

class TaskMailerInterceptorTest < ActionMailer::TestCase
  test "interceptor rewrites teamhub subject" do
    task = tasks(:one)
    notification = TaskAssignedNotification.create!(
      user: users(:one),
      kind: :task_assigned,
      payload: {
        message: "Alice assigned task \"#{task.title}\".",
        task_id: task.id,
        project_id: task.project_id
      }.to_json
    )

    mail = TaskMailer.with(notification_id: notification.id).task_notification.deliver_now
    assert_match(/\A\[Intercepted\] \[TeamHub\]/, mail.subject)
  end
end
