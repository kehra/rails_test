module Teamhub
  class RequestAuditMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      env["teamhub.middleware_chain"] = Array(env["teamhub.middleware_chain"]) << "audit"
      status, headers, body = @app.call(env)
      headers["X-TeamHub-Middleware"] = env["teamhub.middleware_chain"].join(",")
      [ status, headers, body ]
    end
  end
end
