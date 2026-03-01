# frozen_string_literal: true

require_relative "environment"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.log_level = :warn
end
