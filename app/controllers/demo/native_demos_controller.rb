class Demo::NativeDemosController < ApplicationController
  before_action :authenticate_user!

  def recede
    recede_or_redirect_to(root_path, notice: "Handled by web redirect")
  end

  def resume
    resume_or_redirect_to(root_path, notice: "Handled by web redirect")
  end

  def refresh
    refresh_or_redirect_to(root_path, notice: "Handled by web redirect")
  end
end
