class Notification < ApplicationRecord
  broadcasts_to ->(notification) { [ notification.user, :notification_events ] },
    inserts_by: :append,
    target: "notification_events",
    partial: "notifications/notification"

  belongs_to :user

  enum :kind, { generic: 0, task_assigned: 1, task_updated: 2, announcement_posted: 3 }, default: :generic

  scope :unread, -> { where(read_at: nil) }

  validates :payload, presence: true

  after_create_commit do
    broadcast_prepend_to user, target: "notifications", partial: "notifications/notification", locals: { notification: self }
    broadcast_before_to user, target: "notifications_live_events", html: "<span id=\"notification-before-#{id}\"></span>"
    broadcast_after_to user, target: "notifications_live_events", html: "<span id=\"notification-after-#{id}\"></span>"
    broadcast_append_later_to user, :notification_async_events, target: "notification_async_events", html: "<span id=\"notification-async-#{id}\"></span>"
  end
  after_update_commit do
    broadcast_update_to user, target: ActionView::RecordIdentifier.dom_id(self), partial: "notifications/notification", locals: { notification: self }
    broadcast_replace_to user, target: ActionView::RecordIdentifier.dom_id(self), partial: "notifications/notification", locals: { notification: self }
  end
  after_destroy_commit do
    broadcast_remove_to user, target: ActionView::RecordIdentifier.dom_id(self)
  end

  def payload_hash
    JSON.parse(payload)
  rescue JSON::ParserError
    {}
  end

  def message
    payload_hash["message"].presence || "Notification"
  end
end
