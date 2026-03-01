require_relative "boot"

require "rails/all"
require_relative "../lib/teamhub/public_api_railtie"
require_relative "../lib/teamhub/sample_engine"
require_relative "../lib/teamhub/request_marker_middleware"
require_relative "../lib/teamhub/request_audit_middleware"
require_relative "../lib/rack_echo_app"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module RailsTest
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.active_job.queue_adapter = :solid_queue
    config.log_tags = [ :request_id ]
    config.action_dispatch.x_sendfile_header = "X-Sendfile"
    config.railties_order = [ Teamhub::SampleEngine, :main_app, :all ]
    config.exceptions_app = routes
    config.watchable_dirs[Rails.root.join("app/services").to_s] = [ "rb" ]
    config.watchable_files << Rails.root.join("docs/RAILS_FULL_FEATURES.md").to_s
    config.middleware.use Teamhub::RequestAuditMiddleware
    config.middleware.insert_before Teamhub::RequestAuditMiddleware, Teamhub::RequestMarkerMiddleware

    config.generators do |generators|
      generators.helper false
      generators.stylesheets false
      generators.test_framework :test_unit, fixture: true
    end

    config.app_generators do |generators|
      generators.template_engine :erb
      generators.system_tests nil
    end

    config.before_initialize do |app|
      app.config.x.teamhub ||= ActiveSupport::OrderedOptions.new
      app.config.x.teamhub.before_initialize_ran = true
    end

    config.after_initialize do |app|
      app.config.x.teamhub.after_initialize_ran = true
    end
  end
end
