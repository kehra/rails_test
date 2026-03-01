class SignupsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session[:user_id] = @user.id
      cookies.signed[:cable_user_id] = { value: @user.id, httponly: true }
      redirect_to root_path, notice: "Welcome to TeamHub."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.expect(user: [ :name, :email, :password, :password_confirmation ])
  end
end
