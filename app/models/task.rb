class Task < ApplicationRecord
  include Auditable

  belongs_to :project, touch: true
  belongs_to :assignee, class_name: "User", optional: true, inverse_of: :assigned_tasks
  has_many :comments, dependent: :destroy
  has_many :task_tags, dependent: :destroy
  has_many_attached :files
  has_rich_text :content
  accepts_nested_attributes_for :task_tags, reject_if: ->(attrs) { attrs["name"].blank? }, allow_destroy: true
  delegate :name, to: :project, prefix: true

  enum :status, { todo: 0, in_progress: 1, done: 2 }, default: :todo
  enum :priority, { low: 0, normal: 1, high: 2, urgent: 3 }, default: :normal

  scope :upcoming, -> { where(due_on: Date.current..) }

  validates :title, presence: true

  after_create_commit :enqueue_created_notification
  after_update_commit :enqueue_updated_notification

  private

  def enqueue_created_notification
    enqueue_notification("created")
  end

  def enqueue_updated_notification
    return if previous_changes.except("updated_at", "lock_version").empty?

    enqueue_notification("updated")
  end

  def enqueue_notification(event)
    return unless assignee_id

    TaskNotificationJob.perform_later(task_id: id, actor_id: Current.user&.id, event: event)
    return unless due_on.present?

    TaskReminderJob.set(wait_until: due_on.to_time.end_of_day).perform_later(task_id: id)
  end
end
