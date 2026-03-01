# Preview all emails at http://localhost:3000/rails/mailers/task_mailer
class TaskMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/task_mailer/task_notification
  def task_notification
    notification = Notification.order(created_at: :desc).first || sample_notification
    TaskMailer.with(notification_id: notification.id).task_notification
  end

  private

  def sample_notification
    user = User.first || User.create!(name: "Preview User", email: "preview@example.com", password: "password123", password_confirmation: "password123")
    org = Organization.first || Organization.create!(name: "Preview Org")
    Membership.find_or_create_by!(user: user, organization: org) { |m| m.role = :owner }
    project = org.projects.first || org.projects.create!(name: "Preview Project", status: :active)
    task = project.tasks.create!(title: "Preview Task", assignee: user, status: :todo, priority: :normal)
    user.notifications.create!(
      kind: :task_assigned,
      payload: { message: "Preview notification", task_id: task.id, project_id: project.id }.to_json
    )
  end
end
