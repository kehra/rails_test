require "test_helper"

class TaskTagTest < ActiveSupport::TestCase
  test "composite primary key find works" do
    tag = TaskTag.create!(task: tasks(:one), name: "backend")

    found = TaskTag.find([ tasks(:one).id, "backend" ])

    assert_equal tag.task_id, found.task_id
    assert_equal tag.name, found.name
  end
end
