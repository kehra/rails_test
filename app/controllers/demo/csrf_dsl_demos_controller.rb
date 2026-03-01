class Demo::CsrfDslDemosController < ActionController::Base
  protect_from_forgery with: :exception

  def protected_show
    render plain: "csrf-protected"
  end
end
