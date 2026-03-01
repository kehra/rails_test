class Demo::SecurityDemosController < ApplicationController
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new

  rate_limit to: 2, within: 1.minute, only: :limited,
             by: -> { params[:key].presence || request.remote_ip },
             with: -> { head :too_many_requests },
             store: RATE_LIMIT_STORE

  def csrf_tokens
    render json: {
      create_token: form_authenticity_token(form_options: { action: "/security_demos/create", method: :post }),
      update_token: form_authenticity_token(form_options: { action: "/security_demos/update", method: :patch })
    }
  end

  def csrf_rotate
    token_before = form_authenticity_token
    reset_session
    token_after = form_authenticity_token

    render json: { before: token_before, after: token_after }
  end

  def limited
    render json: { ok: true, key: params[:key] }
  end
end
