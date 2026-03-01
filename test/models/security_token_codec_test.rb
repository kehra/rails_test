require "test_helper"

class SecurityTokenCodecTest < ActiveSupport::TestCase
  test "message verifier round trip works" do
    token = SecurityTokenCodec.sign("teamhub-verifier")
    assert_equal "teamhub-verifier", SecurityTokenCodec.verify(token)
  end

  test "message encryptor round trip works" do
    token = SecurityTokenCodec.encrypt("teamhub-encryptor")
    assert_equal "teamhub-encryptor", SecurityTokenCodec.decrypt(token)
  end
end
