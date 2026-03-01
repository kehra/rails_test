require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "project model declares turbo broadcast macro" do
    source = File.read(Rails.root.join("app/models/project.rb"))

    assert_includes source, "broadcasts :projects"
    assert_includes source, "broadcasts_refreshes :project_refreshes"
  end

  test "store_accessor persists and reads settings keys" do
    project = projects(:one)
    project.color = "blue"
    project.visibility = "internal"
    project.save!

    project.reload
    assert_equal "blue", project.color
    assert_equal "internal", project.visibility
  end
end
