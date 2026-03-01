namespace :teamhub do
  desc "Warm dashboard cache for all users"
  task warm_dashboard_cache: :environment do
    User.find_each do |user|
      stats = DashboardStats.for(user)
      puts "warmed user=#{user.id} orgs=#{stats[:organizations_count]} projects=#{stats[:projects_count]} tasks=#{stats[:tasks_count]} unread=#{stats[:unread_notifications_count]}"
    end
  end

  desc "Print SolidQueue queue stats"
  task queue_stats: :environment do
    puts "solid_queue_jobs=#{SolidQueue::Job.count}"
    puts "solid_queue_ready=#{SolidQueue::ReadyExecution.count}"
    puts "solid_queue_scheduled=#{SolidQueue::ScheduledExecution.count}"
    puts "solid_queue_failed=#{SolidQueue::FailedExecution.count}"
  end

  desc "Print middleware stack"
  task middleware: :environment do
    Rails.application.middleware.each do |middleware|
      puts middleware.klass.name
    end
  end
end
