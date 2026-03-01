class Project < ApplicationRecord
  include Auditable

  class_attribute :transaction_events, default: []

  broadcasts :projects, partial: "projects/project"
  broadcasts_refreshes :project_refreshes

  belongs_to :organization
  has_many :tasks, dependent: :destroy
  has_many :announcements, dependent: :destroy
  store :settings, accessors: %i[color visibility], coder: JSON

  enum :status, { active: 0, archived: 1 }, default: :active

  validates :name, presence: true

  after_find :mark_after_find
  after_touch :mark_after_touch
  after_commit :record_after_commit
  after_rollback :record_after_rollback

  def after_find_ran?
    @after_find_ran == true
  end

  def after_touch_ran?
    @after_touch_ran == true
  end

  def self.reset_transaction_events!
    self.transaction_events = []
  end

  private
    def mark_after_find
      @after_find_ran = true
    end

    def mark_after_touch
      @after_touch_ran = true
    end

    def record_after_commit
      self.class.transaction_events += [ :commit ]
    end

    def record_after_rollback
      self.class.transaction_events += [ :rollback ]
    end
end
