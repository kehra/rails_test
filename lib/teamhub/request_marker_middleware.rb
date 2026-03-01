module Teamhub
  class RequestMarkerMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      env["teamhub.middleware_chain"] = Array(env["teamhub.middleware_chain"]) << "marker"
      @app.call(env)
    end
  end
end
