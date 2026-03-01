require "test_helper"

class SecurityAndStorageTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    post session_url, params: { email: users(:one).email, password: "password123" }
  end

  test "responses include security headers" do
    get root_url

    assert_response :success
    assert_not_nil response.headers["Content-Security-Policy"]
    assert_equal "DENY", response.headers["X-Frame-Options"]
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
  end

  test "new task form enables active storage direct upload" do
    get new_task_url

    assert_response :success
    assert_select "input[type=file][data-direct-upload-url]"
    assert_select "[data-controller='direct-upload']"
    assert_select "[data-action*='direct-upload:error->direct-upload#error']"
    assert_select "[data-direct-upload-target='status']"
  end

  test "filter parameters includes authorization token and password" do
    pattern = Rails.application.config.filter_parameters.first
    source = pattern.is_a?(Regexp) ? pattern.source : pattern.to_s

    assert_includes source, "authorization"
    assert_includes source, "passw"
  end

  test "task attachment can be purged synchronously" do
    task = tasks(:one)
    task.files.attach(io: StringIO.new("sync purge"), filename: "sync.txt", content_type: "text/plain")
    signed_id = task.files.first.blob.signed_id

    assert task.files.attached?

    assert_difference("task.files_attachments.count", -1) do
      delete purge_file_task_path(task, signed_id:)
    end
    assert_redirected_to task_url(task)
  end

  test "task attachment can be queued for purge later" do
    task = tasks(:one)
    task.files.attach(io: StringIO.new("async purge"), filename: "async.txt", content_type: "text/plain")
    signed_id = task.files.first.blob.signed_id

    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs

    assert_enqueued_with(job: ActiveStorage::PurgeJob) do
      delete purge_file_later_task_path(task, signed_id:)
    end
    assert_redirected_to task_url(task)
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
  end
end
