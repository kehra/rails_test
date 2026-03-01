require "test_helper"

class RoutingConstraintsTest < ActionDispatch::IntegrationTest
  setup do
    @organization = organizations(:one)
    @project = projects(:one)
    post session_url, params: { email: users(:one).email, password: "password123" }
  end

  test "nested projects routes under organization" do
    get organization_projects_url(@organization)
    assert_response :success

    get new_organization_project_url(@organization)
    assert_response :success

    assert_difference("Project.count") do
      post organization_projects_url(@organization), params: { project: { name: "Nested Project", description: "via nested", status: :active } }
    end

    assert_redirected_to project_url(Project.last)
    assert_equal @organization.id, Project.last.organization_id
  end

  test "nested tasks routes under project" do
    get project_tasks_url(@project)
    assert_response :success

    get new_project_task_url(@project)
    assert_response :success

    assert_difference("Task.count") do
      post project_tasks_url(@project), params: { task: { title: "Nested Task", description: "nested", status: :todo, priority: :normal, assignee_id: users(:one).id } }
    end

    assert_redirected_to task_url(Task.last)
    assert_equal @project.id, Task.last.project_id
  end

  test "constraint rejects non numeric nested ids" do
    get "/organizations/not-number/projects"
    assert_response :not_found
  end

  test "shallow comment routes create and destroy" do
    assert_difference("Comment.count", 1) do
      post task_comments_url(@project.tasks.first), params: { comment: { body: "hello shallow" } }
    end
    assert_redirected_to task_url(@project.tasks.first)

    comment = Comment.order(:id).last
    assert_difference("Comment.count", -1) do
      delete comment_url(comment)
    end
    assert_redirected_to task_url(@project.tasks.first)
  end

  test "home route redirects to dashboard via routing redirect DSL" do
    get "/home"
    assert_redirected_to "/dashboard"
  end
end
