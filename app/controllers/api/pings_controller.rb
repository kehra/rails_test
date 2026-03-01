module Api
  class PingsController < ActionController::API
    def show
      render json: { ok: true, rails: Rails.version }
    end
  end
end
