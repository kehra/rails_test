require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "delegates project_name to project" do
    task = tasks(:one)
    assert_equal task.project.name, task.project_name
  end
end
