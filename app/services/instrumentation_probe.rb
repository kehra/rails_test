class InstrumentationProbe
  def self.emit
    payloads = []

    ActiveSupport::Notifications.subscribed(->(*args) { payloads << build_payload(*args) }, /teamhub\.probe\./) do
      ActiveSupport::Notifications.instrument("teamhub.probe.started", step: "start")
      ActiveSupport::Notifications.instrument("teamhub.probe.finished", step: "finish")
    end

    payloads
  end

  def self.build_payload(name, _started, _finished, _id, payload)
    { name:, payload: }
  end
  private_class_method :build_payload
end
