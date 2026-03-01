class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_user
  around_action :switch_locale
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  helper_method :current_user
  helper_method :signed_in?

  private

  def set_current_user
    Current.user = User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def current_user
    Current.user
  end

  def authenticate_user!
    return if current_user

    redirect_to new_session_path, alert: "Please sign in first."
  end

  def signed_in?
    current_user.present?
  end

  def default_url_options
    I18n.locale == I18n.default_locale ? {} : { locale: I18n.locale }
  end

  def switch_locale(&action)
    locale = params[:locale].presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def render_not_found
    Rails.error.report(
      ActiveRecord::RecordNotFound.new("record not found"),
      handled: true,
      severity: :warning,
      context: { path: request.path, user_id: current_user&.id }
    )
    redirect_to root_path, alert: "Record not found."
  end
end
