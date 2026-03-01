class RecurringHeartbeatJob < ApplicationJob
  queue_as :default

  def perform
    Rails.event.notify("teamhub.recurring.heartbeat", at: Time.current.iso8601)
  end
end
