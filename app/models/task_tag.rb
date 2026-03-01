class TaskTag < ApplicationRecord
  self.primary_key = %i[task_id name]

  belongs_to :task

  validates :name, presence: true
end
