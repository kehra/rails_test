class Current < ActiveSupport::CurrentAttributes
  attribute :user, :request_id

  cattr_accessor :before_reset_count, default: 0
  cattr_accessor :after_reset_count, default: 0

  before_reset { self.class.before_reset_count += 1 }
  resets { self.class.after_reset_count += 1 }
end
