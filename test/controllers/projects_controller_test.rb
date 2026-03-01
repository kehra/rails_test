require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = projects(:one)
    post session_url, params: { email: users(:one).email, password: "password123" }
  end

  test "should get index" do
    get projects_url
    assert_response :success
  end

  test "should get new" do
    get new_project_url
    assert_response :success
  end

  test "should create project" do
    assert_difference("Project.count") do
      post projects_url, params: { project: { description: @project.description, name: "Project New", organization_id: @project.organization_id, status: @project.status } }
    end

    assert_redirected_to project_url(Project.last)
  end

  test "should show project" do
    get project_url(@project)
    assert_response :success
  end

  test "should get edit" do
    get edit_project_url(@project)
    assert_response :success
  end

  test "should update project" do
    patch project_url(@project), params: { project: { description: @project.description, name: @project.name, organization_id: @project.organization_id, status: @project.status } }
    assert_redirected_to project_url(@project)
  end

  test "should destroy project" do
    project = Project.create!(organization: organizations(:one), name: "Disposable Project", description: "temp", status: :active)

    assert_difference("Project.count", -1) do
      delete project_url(project)
    end

    assert_redirected_to projects_url
  end
end
