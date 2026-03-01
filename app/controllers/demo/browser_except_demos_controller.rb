class Demo::BrowserExceptDemosController < ActionController::Base
  allow_browser versions: { ie: false }, except: :open

  def restricted
    render plain: "browser-except-restricted"
  end

  def open
    render plain: "browser-except-open"
  end
end
