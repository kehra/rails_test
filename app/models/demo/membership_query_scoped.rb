class Demo::MembershipQueryScoped < ApplicationRecord
  self.table_name = "memberships"

  query_constraints :organization_id, :user_id

  enum :role, { member: 0, owner: 1 }, default: :member
end
