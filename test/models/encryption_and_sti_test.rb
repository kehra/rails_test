require "test_helper"

class EncryptionAndStiTest < ActiveSupport::TestCase
  test "user private_note is encrypted at rest" do
    user = users(:one)
    user.update!(private_note: "top secret")

    raw = User.connection.select_value("SELECT private_note FROM users WHERE id = #{user.id}")
    assert_not_equal "top secret", raw
    assert_equal "top secret", user.reload.private_note
  end

  test "notification uses STI subclass" do
    notification = TaskAssignedNotification.create!(
      user: users(:one),
      kind: :task_assigned,
      payload: { message: "assigned" }.to_json
    )

    assert_equal "TaskAssignedNotification", notification.type
    assert_instance_of TaskAssignedNotification, Notification.find(notification.id)
  end
end
