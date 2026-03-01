require "test_helper"
require "rack/mock"

class HostAuthorizationTest < ActiveSupport::TestCase
  test "host authorization allowlist permits configured host and blocks others" do
    app = ->(_env) { [ 200, { "Content-Type" => "text/plain" }, [ "ok" ] ] }
    middleware = ActionDispatch::HostAuthorization.new(app, [ "allowed.example.test" ])

    allowed_status, = middleware.call(Rack::MockRequest.env_for("/", "HTTP_HOST" => "allowed.example.test"))
    blocked_status, = middleware.call(Rack::MockRequest.env_for("/", "HTTP_HOST" => "blocked.example.test"))

    assert_equal 200, allowed_status
    assert_equal 403, blocked_status
  end
end
