require "test_helper"

class TasksMailboxTest < ActiveSupport::TestCase
  test "application mailbox defines multiple routing patterns" do
    source = File.read(Rails.root.join("app/mailboxes/application_mailbox.rb"))

    assert_includes source, "routing \"help@example.test\" => :support"
    assert_includes source, "routing ->(inbound_email)"
    assert_includes source, "routing /^tasks(\\+\\d+)?@/i => :tasks"
    assert_includes source, "routing all: :backstop"
  end

  test "tasks mailbox contains bounce branch and attachment extraction logic" do
    source = File.read(Rails.root.join("app/mailboxes/tasks_mailbox.rb"))

    assert_includes source, "return bounced! unless sender"
    assert_includes source, "return bounced! unless project"
    assert_includes source, "mail.attachments"
    assert_includes source, "Attachments:"
  end
end
