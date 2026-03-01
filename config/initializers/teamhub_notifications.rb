ActiveSupport::Notifications.subscribe("teamhub.task_notification") do |name, started, finished, _id, payload|
  duration_ms = ((finished - started) * 1000).round(1)
  Rails.logger.info(
    "[instrumentation] #{name} task_id=#{payload[:task_id]} actor_id=#{payload[:actor_id]} event=#{payload[:event]} duration_ms=#{duration_ms}"
  )
end
