class BulkPingJob < ApplicationJob
  queue_as do
    options = arguments.first.is_a?(Hash) ? arguments.first : {}
    (options[:queue] || :default).to_sym
  end
  queue_with_priority do
    options = arguments.first.is_a?(Hash) ? arguments.first : {}
    options[:priority] || 10
  end

  def perform(message:, queue: :default, priority: 10)
    Rails.logger.info("[bulk_ping] queue=#{queue} priority=#{priority} message=#{message}")
  end
end
