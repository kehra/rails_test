require "test_helper"

class MiddlewareTaskTest < ActiveSupport::TestCase
  test "middleware stack includes security middleware" do
    stack = Rails.application.middleware.map { |middleware| middleware.klass.name }

    assert_includes stack, "ActionDispatch::ContentSecurityPolicy::Middleware"
    assert_includes stack, "ActionDispatch::Cookies"
  end
end
