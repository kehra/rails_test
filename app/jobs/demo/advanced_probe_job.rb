class Demo::AdvancedProbeJob < ApplicationJob
  class_attribute :events, default: []
  class_attribute :discarded_messages, default: []
  class_attribute :deserialized_marker, default: nil

  queue_as :default
  self.enqueue_after_transaction_commit = false

  before_enqueue { self.class.events += [ :before_enqueue ] }
  around_enqueue do |job, block|
    job.class.events += [ :around_enqueue_before ]
    block.call
    job.class.events += [ :around_enqueue_after ]
  end
  after_enqueue { self.class.events += [ :after_enqueue ] }

  before_perform { self.class.events += [ :before_perform ] }
  around_perform do |job, block|
    job.class.events += [ :around_perform_before ]
    block.call
    job.class.events += [ :around_perform_after ]
  end
  after_perform { self.class.events += [ :after_perform ] }

  retry_on StandardError,
    wait: 1.second,
    queue: :mailers,
    priority: 77,
    jitter: 0.15,
    attempts: :unlimited do |job, error|
      job.class.events += [ :"retry_handler_#{error.class.name.demodulize.underscore}" ]
    end

  discard_on ArgumentError, report: true do |job, error|
    job.class.discarded_messages += [ error.message ]
  end

  def self.reset_probe_state!
    self.events = []
    self.discarded_messages = []
    self.deserialized_marker = nil
  end

  def perform(payload:, mode: :ok)
    case mode.to_sym
    when :discard
      raise ArgumentError, "discarded payload"
    when :retry
      retry_job wait: 2.seconds, queue: :low_priority, priority: 33
    else
      self.class.events += [ :"performed_#{payload.value}" ]
    end
  end

  def serialize
    super.merge("custom_marker" => "advanced-probe")
  end

  def deserialize(job_data)
    self.class.deserialized_marker = job_data["custom_marker"]
    super
  end
end
