require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @task = tasks(:one)
    post session_url, params: { email: users(:one).email, password: "password123" }
  end

  test "should get index" do
    get tasks_url
    assert_response :success
  end

  test "should get new" do
    get new_task_url
    assert_response :success
    assert_select "input[name='task[task_tags_attributes][0][name]']"
  end

  test "should create task" do
    assert_difference("Task.count") do
      post tasks_url, params: { task: { assignee_id: @task.assignee_id, description: @task.description, due_on: @task.due_on, priority: @task.priority, project_id: @task.project_id, status: @task.status, title: @task.title } }
    end

    assert_redirected_to task_url(Task.last)
  end

  test "should show task" do
    get task_url(@task)
    assert_response :success
  end

  test "should get edit" do
    get edit_task_url(@task)
    assert_response :success
  end

  test "should update task" do
    patch task_url(@task), params: { task: { assignee_id: @task.assignee_id, description: @task.description, due_on: @task.due_on, priority: @task.priority, project_id: @task.project_id, status: @task.status, title: @task.title } }
    assert_redirected_to task_url(@task)
  end

  test "should destroy task" do
    assert_difference("Task.count", -1) do
      delete task_url(@task)
    end

    assert_redirected_to tasks_url
  end

  test "record not found reports via rails error reporter" do
    reported = false

    reporter = Rails.error
    reporter.singleton_class.alias_method :__teamhub_original_report, :report
    reporter.singleton_class.define_method(:report) do |*_args, **_kwargs|
      reported = true
    end

    begin
      get task_url(id: "999999")
    ensure
      reporter.singleton_class.alias_method :report, :__teamhub_original_report
      reporter.singleton_class.remove_method :__teamhub_original_report
    end

    assert reported
    assert_redirected_to root_url
  end
end
