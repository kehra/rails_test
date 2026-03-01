require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    post session_url, params: { email: users(:one).email, password: "password123" }
    get dashboard_url
    assert_response :success
  end
end
