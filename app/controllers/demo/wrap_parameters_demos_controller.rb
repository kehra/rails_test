class Demo::WrapParametersDemosController < ActionController::API
  wrap_parameters :payload, format: [ :json ]

  def create
    render json: {
      payload: params[:payload].to_unsafe_h,
      title: params[:title]
    }
  end
end
