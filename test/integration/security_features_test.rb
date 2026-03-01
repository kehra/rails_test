require "test_helper"

class SecurityFeaturesTest < ActionDispatch::IntegrationTest
  test "csrf per form tokens differ by form action and method" do
    get "/security_demos/csrf_tokens"

    assert_response :success
    body = JSON.parse(response.body)
    assert body["create_token"].present?
    assert body["update_token"].present?
    refute_equal body["create_token"], body["update_token"]
  end

  test "csrf token rotates after session reset" do
    get "/security_demos/csrf_rotate"

    assert_response :success
    body = JSON.parse(response.body)
    assert body["before"].present?
    assert body["after"].present?
    refute_equal body["before"], body["after"]
  end

  test "rate limiting throttles repeated requests" do
    get "/security_demos/limited", params: { key: "rate-limit-a" }
    assert_response :success

    get "/security_demos/limited", params: { key: "rate-limit-a" }
    assert_response :success

    get "/security_demos/limited", params: { key: "rate-limit-a" }
    assert_response :too_many_requests
  end
end
