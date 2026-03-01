class Announcement < ApplicationRecord
  include Auditable

  belongs_to :project
  belongs_to :user
  has_rich_text :content
  has_many_attached :files

  validates :title, :body, presence: true

  scope :published, -> { where.not(published_at: nil) }
end
