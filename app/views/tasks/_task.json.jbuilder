json.extract! task, :id, :project_id, :assignee_id, :title, :description, :status, :priority, :due_on, :created_at, :updated_at
json.url task_url(task, format: :json)
