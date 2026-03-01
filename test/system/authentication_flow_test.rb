require "application_system_test_case"

class AuthenticationFlowTest < ApplicationSystemTestCase
  test "user can sign up and reach dashboard" do
    visit new_signup_path

    fill_in "Name", with: "System User"
    fill_in "Email", with: "system-user@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_button "Create account"

    assert_text "TeamHub Dashboard"
    assert_text "Signed in as"
  end
end
