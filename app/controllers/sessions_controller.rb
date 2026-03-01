class SessionsController < ApplicationController
  skip_before_action :set_current_user, only: %i[ new create ]

  def new
    redirect_to root_path if current_user
  end

  def create
    user = User.find_by(email: params[:email].to_s.downcase)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      cookies.signed[:cable_user_id] = { value: user.id, httponly: true }
      redirect_to root_path, notice: "Signed in successfully."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    cookies.delete(:cable_user_id)
    reset_session
    redirect_to new_session_path, notice: "Signed out."
  end
end
