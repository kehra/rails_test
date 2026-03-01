require "test_helper"

class AdvancedActiveJobFeaturesTest < ActiveJob::TestCase
  test "task reminder can be scheduled with wait_until" do
    task = tasks(:one)

    with_solid_queue_adapter do
      assert_difference("SolidQueue::ScheduledExecution.count", 1) do
        TaskReminderJob.set(wait_until: 1.hour.from_now).perform_later(task_id: task.id)
      end
    end
  end

  test "bulk enqueue via perform_all_later works" do
    with_solid_queue_adapter do
      before = SolidQueue::Job.count
      job1 = BulkPingJob.new(message: "one", queue: :default, priority: 20)
      job2 = BulkPingJob.new(message: "two", queue: :mailers, priority: 30)

      ActiveJob.perform_all_later(job1, job2)

      assert_operator SolidQueue::Job.count, :>=, before + 2
    end
  end

  test "dynamic queue and priority are serialized on job instance" do
    job = BulkPingJob.new(message: "q", queue: :mailers, priority: 42)

    assert_equal "mailers", job.queue_name
    assert_equal 42, job.priority
  end

  private
    def with_solid_queue_adapter
      original_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :solid_queue
      yield
    ensure
      ActiveJob::Base.queue_adapter = original_adapter
    end
end
