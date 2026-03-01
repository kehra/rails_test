require "test_helper"

class ActiveSupportFeatureProbeTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  test "custom rescuable class handles multiple exception types" do
    FaultTolerantRunner.last_handled_error = nil
    runner = FaultTolerantRunner.new

    assert_instance_of ArgumentError, runner.call(:argument)
    assert_equal "argument:invalid mode", FaultTolerantRunner.last_handled_error

    assert_instance_of RuntimeError, runner.call(:runtime)
    assert_equal "standard:RuntimeError", FaultTolerantRunner.last_handled_error
  end

  test "notifications subscriber receives multiple events" do
    payloads = InstrumentationProbe.emit

    assert_equal [ "teamhub.probe.started", "teamhub.probe.finished" ], payloads.map { |entry| entry[:name] }
    assert_equal [ "start", "finish" ], payloads.map { |entry| entry[:payload][:step] }
  end

  test "current attributes reset callbacks and block scoping work" do
    before_before = Current.before_reset_count
    before_after = Current.after_reset_count

    Current.set(user: users(:one), request_id: "req-1") do
      assert_equal users(:one), Current.user
      assert_equal "req-1", Current.request_id
    end

    Current.reset

    assert_nil Current.user
    assert_nil Current.request_id
    assert_operator Current.before_reset_count, :>, before_before
    assert_operator Current.after_reset_count, :>, before_after
  end

  test "execution context is scoped and restored after executor wrap" do
    snapshots = ExecutionContextProbe.capture(user: users(:one), request_id: "exec-1")

    assert_equal "exec-1", snapshots[:inside_set][:request_id]
    assert_equal "exec-1", snapshots[:inside_executor][:request_id]
    assert_equal "exec-1", snapshots[:inside_current][:execution_context][:request_id]
    assert_equal users(:one).id, snapshots[:inside_current][:current_user_id]
    assert_equal "exec-1", snapshots[:inside_current][:current_request_id]
    assert_equal({}, snapshots[:after])
  end

  test "time helpers can travel and freeze time" do
    base_time = Time.zone.local(2026, 2, 28, 10, 0, 0)

    travel_to(base_time) do
      assert_equal base_time, Time.current
      assert_equal Date.new(2026, 3, 2), 2.days.from_now.to_date
    end

    freeze_time do
      frozen_now = Time.current
      assert_equal frozen_now, Time.current
    end
  end
end
