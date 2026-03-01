class Comment < ApplicationRecord
  belongs_to :task, counter_cache: true, touch: true
  belongs_to :user

  validates :body, presence: true
end
