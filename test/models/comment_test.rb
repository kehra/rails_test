require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "counter_cache increments and decrements on task" do
    task = tasks(:one)
    before_count = task.comments_count

    comment = nil
    assert_difference -> { task.reload.comments_count }, 1 do
      comment = task.comments.create!(user: users(:one), body: "counter")
    end

    assert_difference -> { task.reload.comments_count }, -1 do
      comment.destroy!
    end

    assert_equal before_count, task.reload.comments_count
  end

  test "touch updates parent task timestamp" do
    task = tasks(:one)
    original = task.updated_at

    travel 1.second do
      task.comments.create!(user: users(:one), body: "touch parent")
    end

    assert task.reload.updated_at > original
  end
end
