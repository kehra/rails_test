class Demo::MacroAuthRealmDemosController < ActionController::Base
  http_basic_authenticate_with name: "macro-realm-user", password: "macro-realm-secret", realm: "TeamHub Realm"

  def protected
    render plain: "macro-realm-protected"
  end
end
