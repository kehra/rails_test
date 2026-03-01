require "test_helper"

class ActiveSupportMiscProbeTest < ActiveSupport::TestCase
  test "active support utility probes run" do
    data = Demo::ActiveSupportMiscProbe.transform_hash

    assert_equal({ "user_name" => "Alice", "meta" => { "request_id" => "req-1" } }, data[:compact])
    assert_equal({ user_name: "Alice", meta: { request_id: "req-1" } }, data[:symbolized])
    assert_equal "Alice", data[:transformed]["USER_NAME"]
    assert_equal "req-1", data[:indifferent]["META"]["REQUEST_ID"]
    assert_equal "Alice", data[:indifferent][:USER_NAME]
  end

  test "with_options and delegate_missing_to are exercised" do
    calls = Demo::ActiveSupportMiscProbe.with_options_result

    assert_equal [ { scope: :teamhub, enabled: true, feature: :support_probe } ], calls
    assert Demo::ActiveSupportMiscProbe.delegate_result
  end

  test "on_load hooks, descendants, deprecator, and broadcast logger work" do
    hook_payloads = Demo::ActiveSupportMiscProbe.run_load_hook
    descendants = Demo::ActiveSupportMiscProbe.descendant_result
    deprecations = Demo::ActiveSupportMiscProbe.deprecation_messages
    logs = Demo::ActiveSupportMiscProbe.broadcast_log

    assert_includes hook_payloads, 1
    assert_includes descendants[:descendants], "Demo::ActiveSupportMiscProbe::DescendantChild"
    assert_includes descendants[:subclasses], "Demo::ActiveSupportMiscProbe::DescendantChild"
    assert_includes deprecations.first, "legacy API"
    assert_includes logs[:primary], "broadcasted"
    assert_includes logs[:secondary], "broadcasted"
  end
end
