require "test_helper"

class PublicApiRailtieTest < ActiveSupport::TestCase
  test "custom railtie initializer sets config" do
    assert_equal true, Rails.application.config.teamhub_public_api.enabled
    assert_equal true, Rails.application.config.teamhub_public_api.before_initializer
    assert_equal true, Rails.application.config.teamhub_public_api.after_initializer
    assert_equal true, Rails.application.config.teamhub_public_api.prepare_hook_loaded
  end

  test "application config covers generators ordering exceptions and watchers" do
    config = Rails.application.config

    assert_equal Teamhub::SampleEngine, config.railties_order.first
    assert_equal Rails.application.routes, config.exceptions_app
    assert_equal false, config.generators.options[:rails][:helper]
    assert_equal false, config.generators.options[:rails][:stylesheets]
    assert_equal :test_unit, config.generators.options[:rails][:test_framework]
    assert_equal :erb, config.app_generators.options[:rails][:template_engine]
    assert_nil config.app_generators.options[:rails][:system_tests]
    assert_includes config.watchable_dirs.keys, Rails.root.join("app/services").to_s
    assert_includes config.watchable_files, Rails.root.join("docs/RAILS_FULL_FEATURES.md").to_s
  end

  test "railtie source includes cli and generator hooks" do
    source = File.read(Rails.root.join("lib/teamhub/public_api_railtie.rb"))

    assert_includes source, "console do |app|"
    assert_includes source, "runner do |app|"
    assert_includes source, "server do |app|"
    assert_includes source, "generators do"
  end
end
