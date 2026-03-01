module Teamhub
  module Generators
    class FeatureGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      def create_initializer
        template "feature_initializer.rb.tt", File.join("config/initializers", "teamhub_#{file_name}.rb")
      end
    end
  end
end
