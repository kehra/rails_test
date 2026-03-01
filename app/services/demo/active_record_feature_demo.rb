class Demo::ActiveRecordFeatureDemo
  def self.readonly_task(id)
    Task.where(id: id).readonly.first
  end

  def self.bulk_insert_tags(task:, names:)
    now = Time.current
    rows = names.map { |name| { task_id: task.id, name: name, created_at: now, updated_at: now } }
    TaskTag.insert_all(rows, unique_by: :index_task_tags_on_task_id_and_name)
  end

  def self.bulk_upsert_tags(task:, names:)
    now = Time.current
    rows = names.map { |name| { task_id: task.id, name: name, created_at: now, updated_at: now } }
    TaskTag.upsert_all(rows, unique_by: :index_task_tags_on_task_id_and_name, update_only: [ :updated_at ])
  end

  def self.task_ids_by_batches(batch_size: 2)
    ids = []
    Task.order(:id).find_in_batches(batch_size:) { |batch| ids.concat(batch.map(&:id)) }
    ids
  end

  def self.bulk_touch_descriptions!(suffix:)
    quoted = ActiveRecord::Base.connection.quote(suffix)
    Task.in_batches(of: 100) do |relation|
      relation.update_all("description = COALESCE(description, '') || #{quoted}")
    end
  end

  def self.optional_assignee_task_count
    Task.left_outer_joins(:assignee).where(assignee_id: nil).count
  end

  def self.async_titles
    Task.order(:id).load_async.map(&:title)
  end

  def self.single_insert_project!(organization:)
    now = Time.current
    Project.insert({
      organization_id: organization.id,
      name: "Inserted Project",
      status: Project.statuses[:active],
      created_at: now,
      updated_at: now
    })

    Project.order(:id).last
  end

  def self.single_upsert_project!(project:)
    Project.upsert({
      id: project.id,
      organization_id: project.organization_id,
      name: "Upserted Project",
      status: project[:status],
      created_at: project.created_at,
      updated_at: Time.current
    })

    project.reload
  end

  def self.counter_probe(task:)
    Task.increment_counter(:comments_count, task.id)
    Task.decrement_counter(:comments_count, task.id)
    Task.update_counters(task.id, comments_count: 2)
    before_touch = task.reload.updated_at
    Task.where(id: task.id).touch_all

    task.reload
    {
      comments_count: task.comments_count,
      touched: task.updated_at > before_touch
    }
  end

  def self.query_probe(commented_task:, uncommented_task:, excluded_project:)
    {
      associated_ids: Task.where.associated(:comments).distinct.ids,
      missing_ids: Task.where.missing(:comments).ids,
      excluding_ids: Project.excluding(excluded_project).ids,
      without_ids: Project.without(excluded_project).ids,
      none_count: Task.none.count,
      or_ids: Task.where(id: commented_task.id).or(Task.where(id: uncommented_task.id)).order(:id).ids,
      and_ids: Task.where(project_id: commented_task.project_id).and(Task.where(assignee_id: commented_task.assignee_id)).ids,
      invert_where_ids: Task.where(status: :done).invert_where.order(:id).ids,
      create_with_priority: Task.create_with(priority: :urgent).new.priority,
      in_order_of_ids: Task.in_order_of(:id, [ uncommented_task.id, commented_task.id ]).limit(2).ids
    }
  end

  def self.rewrite_probe(commented_task:)
    {
      reselect_sql: Task.where(id: commented_task.id).select(:title).reselect(:id).to_sql,
      rewhere_sql: Task.where(status: :todo).rewhere(status: :in_progress).to_sql,
      unscope_sql: Task.order(:id).unscope(:order).to_sql,
      regroup_sql: Task.group(:status).regroup(:priority).to_sql,
      annotate_sql: Task.annotate("feature-probe").optimizer_hints("MAX_EXECUTION_TIME(1000)").to_sql
    }
  end

  def self.sole_probe!(task:)
    {
      sole_id: Task.where(id: task.id).sole.id,
      find_sole_by_id: Task.find_sole_by(id: task.id).id
    }
  end
end
