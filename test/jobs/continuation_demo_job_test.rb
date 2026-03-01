require "test_helper"

class ContinuationDemoJobTest < ActiveJob::TestCase
  class FailingContinuationJob < ApplicationJob
    include ActiveJob::Continuable

    class_attribute :retried_options, default: nil

    def perform
      step :emit_start
      step :explode
    end

    def retry_job(**options)
      self.class.retried_options = options
    end

    private
      def emit_start
        Rails.event.notify("teamhub.continuation.start", source: self.class.name)
      end

      def explode
        raise "boom"
      end
  end

  class EventCollector
    attr_reader :events

    def initialize
      @events = []
    end

    def emit(event)
      @events << event
    end
  end

  test "continuation job emits structured events" do
    collector = EventCollector.new
    Rails.event.subscribe(collector) { |event| event[:name].start_with?("teamhub.continuation") }

    ContinuationDemoJob.perform_now

    names = collector.events.map { |event| event[:name] }
    assert_includes names, "teamhub.continuation.start"
    assert_includes names, "teamhub.continuation.finish"
  ensure
    Rails.event.unsubscribe(collector)
  end

  test "continuation job retries when a later step fails after advancing" do
    FailingContinuationJob.retried_options = nil

    assert_nothing_raised do
      FailingContinuationJob.perform_now
    end

    assert_equal 5.seconds, FailingContinuationJob.retried_options[:wait]
  end
end
