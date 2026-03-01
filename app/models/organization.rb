class Organization < ApplicationRecord
  include Auditable

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :projects, dependent: :destroy

  normalizes :name, with: ->(value) { value.to_s.squish.presence }

  validates :name, presence: true, uniqueness: true
end
