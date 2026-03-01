module Admin
  class DiagnosticsController < ApplicationController
    http_basic_authenticate_with name: ENV.fetch("TEAMHUB_BASIC_USER", "admin"), password: ENV.fetch("TEAMHUB_BASIC_PASSWORD", "secret")

    def show
      render json: { ok: true, component: "diagnostics" }
    end
  end
end
