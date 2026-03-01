require "test_helper"
require "tmpdir"

class ConfigurationAndZeitwerkTest < ActiveSupport::TestCase
  test "application before and after initialize hooks ran" do
    assert_equal true, Rails.application.config.x.teamhub.before_initialize_ran
    assert_equal true, Rails.application.config.x.teamhub.after_initialize_ran
  end

  test "credentials API is readable" do
    assert_kind_of ActiveSupport::EncryptedConfiguration, CredentialsProbe.raw_credentials_object
    assert_nil CredentialsProbe.teamhub_demo_flag
  end

  test "zeitwerk resolves autoloaded constants" do
    assert_equal Teamhub::SampleEngine, "Teamhub::SampleEngine".safe_constantize
    assert_equal CredentialsProbe, "CredentialsProbe".safe_constantize
    assert_includes Rails.autoloaders.main.dirs.map(&:to_s), Rails.root.join("app/services").to_s
  end

  test "test environment overrides application defaults" do
    assert_equal :test, Rails.application.config.active_storage.service
    assert_equal :test, ActionMailer::Base.delivery_method
    assert_equal "example.com", Rails.application.config.action_mailer.default_url_options[:host]
    assert_equal false, Rails.application.config.enable_reloading
    assert_equal false, Rails.application.config.action_controller.allow_forgery_protection
  end

  test "zeitwerk supports explicit reload with a standalone loader" do
    loader = Zeitwerk::Loader.new

    Dir.mktmpdir("zeitwerk-probe") do |dir|
      file = File.join(dir, "ephemeral_probe.rb")
      File.write(file, "class EphemeralProbe\n  VALUE = 1\nend\n")

      loader.push_dir(dir)
      loader.enable_reloading
      loader.setup

      assert_equal 1, EphemeralProbe::VALUE

      sleep 1.1
      File.write(file, "class EphemeralProbe\n  VALUE = 2\nend\n")
      loader.reload

      assert_equal 2, EphemeralProbe::VALUE
    end
  ensure
    loader.unload if loader
  end
end
