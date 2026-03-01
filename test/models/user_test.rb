require "test_helper"
require "base64"

class UserTest < ActiveSupport::TestCase
  test "has_one_attached avatar can be attached" do
    user = users(:one)
    user.avatar.attach(
      io: StringIO.new("avatar-bytes"),
      filename: "avatar.txt",
      content_type: "text/plain"
    )

    assert user.avatar.attached?
    assert_equal "avatar.txt", user.avatar.filename.to_s
  end

  test "image avatar supports variant and representation APIs" do
    user = users(:one)
    png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=")
    user.avatar.attach(io: StringIO.new(png), filename: "pixel.png", content_type: "image/png")

    assert user.avatar.variable?
    variant = user.avatar.variant(resize_to_limit: [ 1, 1 ])
    representation = user.avatar.representation(resize_to_limit: [ 1, 1 ])

    assert_kind_of ActiveStorage::VariantWithRecord, variant
    assert_kind_of ActiveStorage::VariantWithRecord, representation
  end

  test "has_secure_password exposes password reset token api" do
    user = users(:one)

    token = user.password_reset_token

    assert token.present?
    assert_equal user, User.find_by_password_reset_token(token)
    assert_equal user, User.find_by_password_reset_token!(token)
  end
end
