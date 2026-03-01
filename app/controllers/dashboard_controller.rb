class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @organizations = current_user.organizations.order(:name)
    @projects = Project.joins(:organization).where(organization: { id: @organizations.select(:id) }).includes(:organization).limit(10)
    @tasks = Task.joins(project: :organization).where(organizations: { id: @organizations.select(:id) }).includes(:project, :assignee).order(created_at: :desc).limit(10)
    @tasks_preloaded_count = Task.preload(:assignee).limit(5).to_a.size
    @tasks_eager_loaded_count = Task.eager_load(:project).limit(5).to_a.size
    @notifications = current_user.notifications.order(created_at: :desc).limit(10)
    @stats = DashboardStats.for(current_user)
  end
end
