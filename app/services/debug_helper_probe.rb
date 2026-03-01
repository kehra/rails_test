class DebugHelperProbe
  def self.render_console_debug(payload = { teamhub: true, source: "runner" })
    ApplicationController.helpers.debug(payload)
  end
end
