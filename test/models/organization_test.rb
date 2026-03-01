require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "organization normalizes whitespace in name" do
    organization = Organization.new(name: "  Example   Org  ")

    assert_equal "Example Org", organization.name
  end
end
