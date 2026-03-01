require "test_helper"

class ShardedNoteTest < ActiveSupport::TestCase
  test "records can be created on both shards" do
    shard_one_count = ShardedRecord.connected_to(role: :writing, shard: :default) { ShardedNote.count }
    shard_two_count = ShardedRecord.connected_to(role: :writing, shard: :shard_two) { ShardedNote.count }

    ShardedRecord.connected_to(role: :writing, shard: :default) do
      ShardedNote.create!(external_key: "note-shard-one", body: "Stored on shard one")
    end

    ShardedRecord.connected_to(role: :writing, shard: :shard_two) do
      ShardedNote.create!(external_key: "note-shard-two", body: "Stored on shard two")
    end

    assert_equal shard_one_count + 1, ShardedRecord.connected_to(role: :writing, shard: :default) { ShardedNote.count }
    assert_equal shard_two_count + 1, ShardedRecord.connected_to(role: :writing, shard: :shard_two) { ShardedNote.count }
  end
end
