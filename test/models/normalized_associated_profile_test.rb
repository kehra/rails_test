require "test_helper"

class NormalizedAssociatedProfileTest < ActiveSupport::TestCase
  test "plain model normalizes attributes" do
    profile = Demo::NormalizedAssociatedProfile.new(email: "  USER@Example.TEST  ")

    assert_equal "user@example.test", profile.email
  end

  test "plain model validates associated object" do
    profile = Demo::NormalizedAssociatedProfile.new(
      email: "user@example.test",
      contact: Demo::NormalizedAssociatedProfile::Contact.new(email: nil)
    )

    assert_not profile.valid?
    assert_includes profile.errors[:contact], "is invalid"
  end
end
