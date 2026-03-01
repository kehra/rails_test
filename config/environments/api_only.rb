require_relative "production"

Rails.application.configure do
  config.api_only = true
end
