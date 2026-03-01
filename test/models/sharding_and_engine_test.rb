require "test_helper"

class ShardingAndEngineTest < ActiveSupport::TestCase
  test "sharded record switches connections by shard" do
    default_name = ShardedRecord.connected_to(role: :writing, shard: :default) do
      ShardedRecord.connection_db_config.name
    end

    shard_two_name = ShardedRecord.connected_to(role: :writing, shard: :shard_two) do
      ShardedRecord.connection_db_config.name
    end

    assert_equal "primary_shard_one", default_name
    assert_equal "primary_shard_two", shard_two_name
  end

  test "application record switches between writing and reading roles" do
    writing_prevent_writes = ApplicationRecord.connected_to(role: :writing) { ApplicationRecord.current_preventing_writes }
    reading_prevent_writes = ApplicationRecord.connected_to(role: :reading) { ApplicationRecord.current_preventing_writes }

    assert_equal false, writing_prevent_writes
    assert_equal true, reading_prevent_writes
  end

  test "sample engine class is defined" do
    assert Teamhub::SampleEngine < Rails::Engine
    assert Teamhub::SampleEngine.engine_name.present?
    assert_includes Teamhub::SampleEngine.paths["config/routes.rb"].to_a.join(","), "lib/teamhub/sample_engine/config/routes.rb"
    assert_includes Teamhub::SampleEngine.paths["config/locales"].to_a.join(","), "lib/teamhub/sample_engine/config/locales"
    assert_includes Teamhub::SampleEngine.paths["app/assets"].to_a.join(","), "lib/teamhub/sample_engine/app/assets"
    assert_includes Teamhub::SampleEngine.routes.routes.map(&:path).map(&:spec).map(&:to_s), "/prefixed(.:format)"
    assert_includes Teamhub::SampleEngine.routes.routes.map(&:path).map(&:spec).map(&:to_s), "/appended(.:format)"
  end

  test "engine discovery APIs resolve sample engine namespace" do
    assert_instance_of Teamhub::SampleEngine, Rails::Engine.find(Teamhub::SampleEngine.root.to_s)
    assert_equal Teamhub::SampleEngine.root, Teamhub::SampleEngine.find_root(Teamhub::SampleEngine.root.to_s)
  end

  test "api_only environment config enables api_only mode" do
    body = File.read(Rails.root.join("config/environments/api_only.rb"))

    assert_includes body, "config.api_only = true"
  end
end
