require "test_helper"

class AdvancedProbeJobTest < ActiveJob::TestCase
  setup do
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    clear_performed_jobs
    Demo::AdvancedProbeJob.reset_probe_state!
  end

  test "job callbacks and enqueue result inspection work" do
    yielded_job = nil

    job = Demo::AdvancedProbeJob.perform_later(payload: Demo::JobProbePayload.new("enqueue")) do |enqueued_job|
      yielded_job = enqueued_job
    end

    assert job.successfully_enqueued?
    assert_nil job.enqueue_error
    assert_equal job, yielded_job
    assert_equal [
      :before_enqueue,
      :around_enqueue_before,
      :after_enqueue,
      :around_enqueue_after
    ], Demo::AdvancedProbeJob.events
  end

  test "set options and custom serializers are reflected in enqueued job payload" do
    Demo::AdvancedProbeJob.set(wait: 5.minutes, queue: :mailers, priority: 25).perform_later(payload: Demo::JobProbePayload.new("serialized"))

    enqueued = enqueued_jobs.last

    assert_equal "mailers", enqueued[:queue]
    assert_equal 25, enqueued[:priority]
    assert_operator enqueued[:at], :>, Time.current.to_f
    serialized_payload = enqueued[:args].first["payload"]["value"]
    assert_equal "serialized", serialized_payload
    assert_equal "Demo::JobProbePayloadSerializer", enqueued[:args].first["payload"]["_aj_serialized"]
  end

  test "perform callbacks and deserialize override run during perform_enqueued_jobs" do
    perform_enqueued_jobs do
      Demo::AdvancedProbeJob.perform_later(payload: Demo::JobProbePayload.new("perform"))
    end

    assert_equal "advanced-probe", Demo::AdvancedProbeJob.deserialized_marker
    assert_equal [
      :before_enqueue,
      :around_enqueue_before,
      :before_perform,
      :around_perform_before,
      :performed_perform,
      :after_perform,
      :around_perform_after,
      :after_enqueue,
      :around_enqueue_after
    ], Demo::AdvancedProbeJob.events
  end

  test "discard handler records message and job disables transaction defer" do
    assert_equal false, Demo::AdvancedProbeJob.enqueue_after_transaction_commit

    perform_enqueued_jobs do
      Demo::AdvancedProbeJob.perform_later(payload: Demo::JobProbePayload.new("discard"), mode: :discard)
    end

    assert_includes Demo::AdvancedProbeJob.discarded_messages, "discarded payload"
  end

  test "advanced retry and retry_job re-enqueue configuration work" do
    Demo::AdvancedProbeJob.perform_now(payload: Demo::JobProbePayload.new("retry"), mode: :retry)

    retried = enqueued_jobs.last
    source = File.read(Rails.root.join("app/jobs/demo/advanced_probe_job.rb"))
    serializer_initializer = File.read(Rails.root.join("config/initializers/active_job_probe_serializer.rb"))

    assert_equal Demo::AdvancedProbeJob, retried[:job]
    assert_equal "low_priority", retried[:queue]
    assert_equal 33, retried[:priority]
    assert_operator retried[:at], :>, Time.current.to_f
    assert_includes source, "retry_on StandardError"
    assert_includes source, "attempts: :unlimited"
    assert_includes source, "jitter: 0.15"
    assert_includes source, "queue: :mailers"
    assert_includes source, "priority: 77"
    assert_includes source, "discard_on ArgumentError, report: true"
    assert_includes source, "retry_job wait: 2.seconds, queue: :low_priority, priority: 33"
    assert_includes serializer_initializer, "ActiveJob::Serializers.add_serializers(Demo::JobProbePayloadSerializer)"
  end
end
