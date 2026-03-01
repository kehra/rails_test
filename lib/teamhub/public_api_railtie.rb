module Teamhub
  class PublicApiRailtie < Rails::Railtie
    config.teamhub_public_api = ActiveSupport::OrderedOptions.new

    initializer "teamhub.public_api.before", before: "load_config_initializers" do |app|
      app.config.teamhub_public_api.before_initializer = true
    end

    initializer "teamhub.public_api.enable" do |app|
      app.config.teamhub_public_api.enabled = true
    end

    initializer "teamhub.public_api.after", after: "teamhub.public_api.enable" do |app|
      app.config.teamhub_public_api.after_initializer = true
    end

    config.to_prepare do
      Rails.application.config.teamhub_public_api.prepare_hook_loaded = true
    end

    console do |app|
      app.config.teamhub_public_api.console_hook_loaded = true
    end

    runner do |app|
      app.config.teamhub_public_api.runner_hook_loaded = true
    end

    server do |app|
      app.config.teamhub_public_api.server_hook_loaded = true
    end

    generators do
      Rails.application.config.teamhub_public_api.generator_hook_loaded = true
    end

    rake_tasks do
      namespace :teamhub do
        desc "Probe custom Railtie wiring"
        task railtie_probe: :environment do
          puts Rails.application.config.teamhub_public_api.enabled ? "enabled" : "disabled"
        end
      end
    end
  end
end
