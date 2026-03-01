require "test_helper"

class ActiveRecordCallbacksProbeTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    Project.reset_transaction_events!
  end

  teardown do
    Project.where("name LIKE ?", "Callback probe%").delete_all
    Project.reset_transaction_events!
  end

  test "project lifecycle callbacks cover find touch commit and rollback" do
    project = Project.find(projects(:one).id)

    assert project.after_find_ran?

    project.touch

    assert project.after_touch_ran?
    assert_includes Project.transaction_events, :commit

    Project.reset_transaction_events!

    Project.transaction do
      Project.create!(organization: organizations(:one), name: "Callback probe rollback")
      raise ActiveRecord::Rollback
    end

    assert_includes Project.transaction_events, :rollback
  end
end
