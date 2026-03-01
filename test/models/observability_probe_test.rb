require "test_helper"

class ObservabilityProbeTest < ActiveSupport::TestCase
  test "rails error handle consumes matching exception" do
    assert_nothing_raised do
      ObservabilityProbe.handle_demo
    end
  end

  test "rails error record forwards rescued exception" do
    calls = []
    reporter = Rails.error
    reporter.singleton_class.alias_method :__teamhub_original_record, :record
    reporter.singleton_class.define_method(:record) do |error, **kwargs|
      calls << [ error.class.name, kwargs[:severity], kwargs[:context] ]
    end

    begin
      ObservabilityProbe.record_demo
    ensure
      reporter.singleton_class.alias_method :record, :__teamhub_original_record
      reporter.singleton_class.remove_method :__teamhub_original_record
    end

    assert_equal 1, calls.size
    assert_equal "StandardError", calls.first[0]
    assert_equal :warning, calls.first[1]
    assert_equal({ source: "ObservabilityProbe" }, calls.first[2])
  end

  test "tagged logging is configured and usable" do
    assert_includes Array(Rails.application.config.log_tags), :request_id
    assert_nothing_raised do
      ObservabilityProbe.tagged_log_demo
    end
  end
end
