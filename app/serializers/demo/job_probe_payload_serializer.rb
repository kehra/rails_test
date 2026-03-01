require Rails.root.join("app/models/demo")
require Rails.root.join("app/models/demo/job_probe_payload")

class Demo::JobProbePayloadSerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize?(argument)
    argument.is_a?(Demo::JobProbePayload)
  end

  def serialize(payload)
    super("value" => payload.value)
  end

  def deserialize(hash)
    Demo::JobProbePayload.new(hash["value"])
  end

  def klass
    Demo::JobProbePayload
  end
end
