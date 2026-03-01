class Demo::ErrorDemosController < ApplicationController
  before_action :authenticate_user!

  rescue_from ArgumentError, with: :render_bad_request
  rescue_from KeyError, with: :render_unprocessable

  def show
    case params[:kind]
    when "argument"
      raise ArgumentError, "bad input"
    when "key"
      raise KeyError, "missing key"
    else
      render json: { ok: true }
    end
  end

  private
    def render_bad_request(error)
      render json: { error: error.message, type: error.class.name }, status: :bad_request
    end

    def render_unprocessable(error)
      render json: { error: error.message, type: error.class.name }, status: :unprocessable_entity
    end
end
