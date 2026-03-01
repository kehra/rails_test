class Demo::MacroAuthDemosController < ApplicationController
  http_basic_authenticate_with name: "macro-user", password: "macro-secret", only: :protected

  def protected
    render plain: "macro-protected"
  end

  def open
    render plain: "macro-open"
  end
end
