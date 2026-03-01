class Demo::BrowserScopeDemosController < ActionController::Base
  allow_browser versions: { ie: false }, only: :restricted

  def restricted
    render plain: "browser-scope-restricted"
  end

  def open
    render plain: "browser-scope-open"
  end
end
