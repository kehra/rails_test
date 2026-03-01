class ShardedNote < ShardedRecord
  validates :body, presence: true
end
