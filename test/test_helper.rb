ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module SQLiteParallelTestDatabaseFix
  def schema_up_to_date?(configuration, *args)
    super
  rescue ActiveRecord::StatementInvalid => error
    raise unless missing_internal_metadata_table?(error)

    false
  end

  private
    def missing_internal_metadata_table?(error)
      messages = []
      current = error

      while current
        messages << current.message
        current = current.respond_to?(:cause) ? current.cause : nil
      end

      messages.any? { |message| message.include?("no such table: ar_internal_metadata") }
    end
end

ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(SQLiteParallelTestDatabaseFix)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: 10)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
