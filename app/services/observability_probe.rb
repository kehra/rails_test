class ObservabilityProbe
  def self.handle_demo
    Rails.error.handle(StandardError, severity: :warning) do
      raise StandardError, "handled by Rails.error.handle"
    end
  end

  def self.record_demo
    begin
      raise StandardError, "recorded by Rails.error.record"
    rescue StandardError => error
      Rails.error.record(error, severity: :warning, context: { source: name })
    end
  end

  def self.tagged_log_demo
    Rails.logger.tagged("teamhub-observe") do
      Rails.logger.info("[observability_probe] tagged log")
    end
  end
end
