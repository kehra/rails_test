class DashboardStats
  CACHE_TTL = 10.minutes

  def self.for(user)
    org_ids = user.organization_ids.sort
    cache_key = [
      "dashboard-stats",
      user.id,
      org_ids.hash,
      project_version(org_ids),
      task_version(org_ids),
      notification_version(user.id)
    ]

    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      {
        organizations_count: org_ids.size,
        projects_count: Project.where(organization_id: org_ids).count,
        tasks_count: Task.joins(:project).where(projects: { organization_id: org_ids }).count,
        unread_notifications_count: user.notifications.unread.count
      }
    end
  end

  def self.project_version(org_ids)
    Project.where(organization_id: org_ids).maximum(:updated_at)&.to_i || 0
  end

  def self.task_version(org_ids)
    Task.joins(:project).where(projects: { organization_id: org_ids }).maximum(:updated_at)&.to_i || 0
  end

  def self.notification_version(user_id)
    Notification.where(user_id: user_id).maximum(:updated_at)&.to_i || 0
  end
end
