class Demo::MacroAuthExceptDemosController < ActionController::Base
  http_basic_authenticate_with name: "macro-except-user", password: "macro-except-secret", except: :open

  def protected
    render plain: "macro-except-protected"
  end

  def open
    render plain: "macro-except-open"
  end
end
