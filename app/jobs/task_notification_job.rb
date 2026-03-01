class TaskNotificationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 1.second, attempts: 3
  discard_on ActiveJob::DeserializationError

  def perform(task_id:, actor_id:, event:)
    ActiveSupport::Notifications.instrument("teamhub.task_notification", task_id:, actor_id:, event:) do
      Rails.event.notify("teamhub.task_notification", task_id:, actor_id:, event:)
      task = Task.includes(:project, :assignee).find(task_id)
      return unless task.assignee

      actor = User.find_by(id: actor_id)

      notification_class = event == "created" ? TaskAssignedNotification : TaskUpdatedNotification
      notification = notification_class.create!(
        user: task.assignee,
        kind: event == "created" ? :task_assigned : :task_updated,
        payload: {
          message: notification_message(task:, actor:, event:),
          task_id: task.id,
          task_title: task.title,
          project_id: task.project_id,
          event: event
        }.to_json
      )

      NotificationsChannel.broadcast_to(
        task.assignee,
        id: notification.id,
        message: notification.message,
        created_at: notification.created_at.iso8601
      )
      ActionCable.server.broadcast(
        "teamhub:events:#{task.assignee_id}",
        event: event,
        task_id: task.id,
        notification_id: notification.id
      )

      TaskMailer.with(notification_id: notification.id).task_notification.deliver_later
    end
  end

  private

  def notification_message(task:, actor:, event:)
    actor_name = actor&.name || "System"

    if event == "created"
      "#{actor_name} assigned task \"#{task.title}\"."
    else
      "#{actor_name} updated task \"#{task.title}\"."
    end
  end
end
