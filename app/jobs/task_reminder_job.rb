class TaskReminderJob < ApplicationJob
  queue_as :default
  queue_with_priority 50

  def perform(task_id:)
    task = Task.find_by(id: task_id)
    return unless task&.assignee

    Notification.create!(
      user: task.assignee,
      kind: :task_updated,
      payload: {
        message: "Reminder: task \"#{task.title}\" is due.",
        task_id: task.id,
        event: "reminder"
      }.to_json
    )
  end
end
