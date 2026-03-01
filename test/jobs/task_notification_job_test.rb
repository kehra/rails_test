require "test_helper"

class TaskNotificationJobTest < ActiveJob::TestCase
  test "perform creates notification for assignee" do
    task = tasks(:one)
    events = []
    subscriber = ActiveSupport::Notifications.subscribe("teamhub.task_notification") do |_name, _started, _finished, _id, payload|
      events << payload
    end

    assert_difference "Notification.count", 1 do
      TaskNotificationJob.perform_now(task_id: task.id, actor_id: users(:two).id, event: "updated")
    end

    notification = Notification.order(:id).last
    assert_equal users(:one), notification.user
    assert_equal "task_updated", notification.kind
    assert_includes notification.message, task.title
    assert_equal 1, events.size
    assert_equal task.id, events.first[:task_id]
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end

  test "perform emits matching payloads to notifications and rails event" do
    task = tasks(:one)
    notifications_payloads = []
    rail_events = []

    notifications_subscriber = ActiveSupport::Notifications.subscribe("teamhub.task_notification") do |_name, _started, _finished, _id, payload|
      notifications_payloads << payload
    end

    collector = Object.new
    collector.define_singleton_method(:emit) do |event|
      rail_events << event
    end
    Rails.event.subscribe(collector) { |event| event[:name] == "teamhub.task_notification" }

    TaskNotificationJob.perform_now(task_id: task.id, actor_id: users(:two).id, event: "updated")

    assert_equal 1, notifications_payloads.size
    assert_equal 1, rail_events.size
    assert_equal "teamhub.task_notification", rail_events.first[:name]
    assert_equal notifications_payloads.first[:task_id], rail_events.first[:payload][:task_id]
    assert_equal notifications_payloads.first[:actor_id], rail_events.first[:payload][:actor_id]
    assert_equal notifications_payloads.first[:event], rail_events.first[:payload][:event]
  ensure
    ActiveSupport::Notifications.unsubscribe(notifications_subscriber) if notifications_subscriber
    Rails.event.unsubscribe(collector) if collector
  end
end
