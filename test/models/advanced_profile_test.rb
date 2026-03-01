require "test_helper"

class AdvancedProfileTest < ActiveSupport::TestCase
  test "advanced profile uses dirty callbacks serialization and validation APIs" do
    profile = Demo::AdvancedProfile.new(
      name: "Alice",
      email: "alice@example.test",
      status: "active",
      code: "OK",
      nickname: nil,
      token: nil,
      password: "secret123",
      password_confirmation: "secret123",
      terms: "1",
      address: Demo::AdvancedProfile::Address.new(city: "Tokyo")
    )

    assert profile.valid?
    assert profile.changed?
    assert_equal [ nil, "Alice" ], profile.changes["name"]
    assert_equal({ "name" => "Alice", "email" => "alice@example.test", "status" => "active" }, profile.serializable_hash)
    assert_equal({ "name" => "Alice", "email" => "alice@example.test", "status" => "active" }, profile.as_json)

    profile.publish

    assert profile.published?
    assert profile.before_publish_ran?
    assert profile.after_publish_ran?
    assert_not profile.changed?
    assert_equal false, profile.persisted?
    assert_nil profile.to_key
    assert_nil profile.to_param
  end

  test "advanced profile strict and helper validations fail as expected" do
    invalid = Demo::AdvancedProfile.new(
      name: "ad",
      email: "bad@example.org",
      status: "paused",
      code: "BAD",
      nickname: "nick",
      token: "secret-token",
      password: "secret123",
      password_confirmation: "mismatch",
      terms: "0",
      address: Demo::AdvancedProfile::Address.new(city: nil)
    )

    error = assert_raises(ActiveModel::StrictValidationFailed) { invalid.valid? }
    assert_includes error.message, "Token"

    invalid.token = nil
    assert_not invalid.valid?
    assert_includes invalid.errors[:terms], "must be accepted"
    assert_includes invalid.errors[:password_confirmation], "doesn't match Password"
    assert_includes invalid.errors[:name].join, "too short"
    assert_includes invalid.errors[:email].join, "must use example.test"
    assert_includes invalid.errors[:status].join, "is not included"
    assert_includes invalid.errors[:code].join, "is reserved"
    assert_includes invalid.errors[:nickname].join, "must be blank"
    assert_includes invalid.errors[:address].join, "is invalid"
  end

  test "advanced profile custom validators add reserved name error" do
    profile = Demo::AdvancedProfile.new(
      name: "admin",
      email: "admin@example.test",
      status: "active",
      code: "OK",
      nickname: nil,
      token: nil,
      password: "secret123",
      password_confirmation: "secret123",
      terms: "1",
      address: Demo::AdvancedProfile::Address.new(city: "Osaka")
    )

    assert_not profile.valid?
    assert_includes profile.errors[:name].join, "cannot be reserved"
  end
end
