require "test_helper"
require Rails.root.join("lib/generators/teamhub/feature/feature_generator")

class CustomGeneratorTest < ActiveSupport::TestCase
  test "teamhub custom generator is defined with template source" do
    assert defined?(Teamhub::Generators::FeatureGenerator)

    source_root = Teamhub::Generators::FeatureGenerator.source_root
    assert source_root.end_with?("lib/generators/teamhub/feature/templates")
    assert File.exist?(Rails.root.join("lib/generators/teamhub/feature/templates/feature_initializer.rb.tt"))
  end
end
