require "test_helper"

class TaskImportFormTest < ActiveSupport::TestCase
  test "valid form builds task attributes" do
    form = TaskImportForm.new(title: "  Imported Task  ", description: "from file", due_on: Date.current + 1.day)

    assert form.valid?
    attrs = form.to_task_attributes
    assert_equal "Imported Task", attrs[:title]
    assert_equal "from file", attrs[:description]
    assert_equal :todo, attrs[:status]
    assert_equal :normal, attrs[:priority]
  end

  test "custom ActiveModel type squishes whitespace" do
    form = TaskImportForm.new(title: "  Imported   Task  ", description: "  deeply   spaced   text  ", due_on: Date.current + 1.day)

    assert form.valid?
    assert_equal "Imported Task", form.title
    assert_equal "deeply spaced text", form.description
  end

  test "invalid without title" do
    form = TaskImportForm.new(title: "   ")

    assert_not form.valid?
    assert_includes form.errors[:title], "can't be blank"
  end
end
