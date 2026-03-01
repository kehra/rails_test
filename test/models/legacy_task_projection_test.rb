require "test_helper"

class LegacyTaskProjectionTest < ActiveSupport::TestCase
  test "ignored columns hide legacy attributes from the model" do
    projection = Demo::LegacyTaskProjection.find(tasks(:one).id)

    refute_includes Demo::LegacyTaskProjection.column_names, "description"
    assert_raises(NoMethodError) { projection.description }
  end
end
