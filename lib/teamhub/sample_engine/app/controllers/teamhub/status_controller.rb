module Teamhub
  class StatusController < ActionController::Base
    def show
      render json: { engine: "teamhub_sample_engine", status: "ok" }
    end
  end
end
