require "test_helper"

class DebugHelperProbeTest < ActiveSupport::TestCase
  test "debug helper probe renders inspect payload for console style usage" do
    rendered = DebugHelperProbe.render_console_debug(teamhub: true, source: "runner")

    assert_includes rendered, "debug_dump"
    assert_includes rendered, "teamhub"
    assert_includes rendered, "runner"
  end
end
