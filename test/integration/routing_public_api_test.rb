require "test_helper"

class RoutingPublicApiTest < ActionDispatch::IntegrationTest
  setup do
    post session_url, params: { email: users(:one).email, password: "password123" }
  end

  test "resolve maps Profile to singular profile path" do
    assert_equal profile_path, polymorphic_path(Profile.new)
  end
end
