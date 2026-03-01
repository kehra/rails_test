require "test_helper"

class HttpI18nAndExportTest < ActionDispatch::IntegrationTest
  setup do
    @task = tasks(:one)
    post session_url, params: { email: users(:one).email, password: "password123" }
  end

  test "dashboard switches locale with query param" do
    get root_url(locale: :ja)

    assert_response :success
    assert_includes response.body, "TeamHub ダッシュボード"
  end

  test "task show supports conditional get" do
    get task_url(@task)
    assert_response :success

    last_modified = response.headers["Last-Modified"]
    get task_url(@task), headers: { "If-Modified-Since" => last_modified }
    assert_response :not_modified
  end

  test "tasks export returns csv via send_data" do
    get export_tasks_url(format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.body, "id,title,project,assignee,status,priority,due_on"
  end

  test "tasks export_file returns csv via send_file" do
    get export_file_tasks_url(format: :csv)

    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match(/attachment;.*tasks-file-/, response.headers["Content-Disposition"])
    assert_match %r{/tmp/tasks-.*\.csv}, response.headers["X-Sendfile"]
    assert_equal "0", response.headers["Content-Length"]
  end
end
