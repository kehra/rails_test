require Rails.root.join("app/models/demo")
require Rails.root.join("app/serializers/demo/job_probe_payload_serializer")

ActiveJob::Serializers.add_serializers(Demo::JobProbePayloadSerializer)
