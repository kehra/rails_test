require "test_helper"

class ActionMailerPublicApiTest < ActiveSupport::TestCase
  test "mailer helper apis are callable" do
    mailer = AdvancedMailer.new

    assert_equal "TeamHub Bot <bot@example.test>", mailer.email_address_with_name("bot@example.test", "TeamHub Bot")
  end

  test "preview registry api and preview interceptors are callable" do
    ActionMailer::Base.register_preview_interceptors("AdvancedMailerPreviewInterceptor")
    preview = ActionMailer::Preview.find("advanced_mailer")
    message = preview.call("digest_report")

    assert ActionMailer::Preview.exists?("advanced_mailer")
    assert_includes ActionMailer::Preview.all.map(&:preview_name), "advanced_mailer"
    assert_equal [ "digest_report" ], preview.emails
    assert_equal "advanced_mailer", preview.preview_name
    assert_equal "true", message["X-Preview-Intercepted"].to_s
  ensure
    ActionMailer::Base.unregister_preview_interceptors("AdvancedMailerPreviewInterceptor")
  end
end
