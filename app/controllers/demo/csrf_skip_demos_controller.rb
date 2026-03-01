class Demo::CsrfSkipDemosController < ActionController::Base
  skip_forgery_protection

  def show
    render plain: "csrf-skipped"
  end
end
