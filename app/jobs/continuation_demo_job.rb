class ContinuationDemoJob < ApplicationJob
  include ActiveJob::Continuable

  queue_as :default

  def perform
    step :emit_start
    step :emit_finish
  end

  private

  def emit_start
    Rails.event.notify("teamhub.continuation.start", source: self.class.name)
  end

  def emit_finish
    Rails.event.notify("teamhub.continuation.finish", source: self.class.name)
  end
end
