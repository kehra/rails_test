require "test_helper"

class ActiveRecordFeatureDemoTest < ActiveSupport::TestCase
  test "readonly relation cannot be updated" do
    readonly = Demo::ActiveRecordFeatureDemo.readonly_task(tasks(:one).id)

    assert readonly.readonly?
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      readonly.update!(title: "updated")
    end
  end

  test "strict_loading raises when lazy loading association" do
    task = Task.strict_loading.find(tasks(:one).id)

    assert_raises(ActiveRecord::StrictLoadingViolationError) do
      task.project
    end
  end

  test "insert_all and upsert_all work with composite key table" do
    task = tasks(:one)
    TaskTag.where(task_id: task.id, name: "bulk-tag").delete_all

    assert_difference("TaskTag.where(task_id: task.id, name: 'bulk-tag').count", 1) do
      Demo::ActiveRecordFeatureDemo.bulk_insert_tags(task:, names: [ "bulk-tag" ])
    end

    assert_no_difference("TaskTag.where(task_id: task.id, name: 'bulk-tag').count") do
      Demo::ActiveRecordFeatureDemo.bulk_upsert_tags(task:, names: [ "bulk-tag" ])
    end
  end

  test "find_in_batches and in_batches execute" do
    ids = Demo::ActiveRecordFeatureDemo.task_ids_by_batches(batch_size: 1)
    assert_includes ids, tasks(:one).id

    Demo::ActiveRecordFeatureDemo.bulk_touch_descriptions!(suffix: "-batch")
    assert Task.where("description LIKE ?", "%-batch").exists?
  end

  test "left_outer_joins handles optional assignee relation" do
    task = Task.create!(project: projects(:one), title: "No assignee", status: :todo, priority: :low)

    count = Demo::ActiveRecordFeatureDemo.optional_assignee_task_count

    assert_operator count, :>=, 1
    assert_nil task.assignee_id
  end

  test "load_async relation can be consumed" do
    titles = Demo::ActiveRecordFeatureDemo.async_titles

    assert_includes titles, tasks(:one).title
  end

  test "single row persistence APIs insert and upsert work" do
    inserted = Demo::ActiveRecordFeatureDemo.single_insert_project!(organization: organizations(:one))
    upserted = Demo::ActiveRecordFeatureDemo.single_upsert_project!(project: projects(:one))

    assert_equal "Inserted Project", inserted.name
    assert_equal "Upserted Project", upserted.name
  end

  test "counter helpers and touch_all update counters and timestamps" do
    task = Task.create!(project: projects(:one), title: "Counter probe", status: :todo, priority: :low)

    result = Demo::ActiveRecordFeatureDemo.counter_probe(task:)

    assert_equal 2, result[:comments_count]
    assert result[:touched]
  end

  test "query composition and builder helpers execute" do
    uncommented = Task.create!(
      project: projects(:one),
      assignee: users(:one),
      title: "Uncommented",
      status: :todo,
      priority: :low
    )
    done_task = Task.create!(
      project: projects(:one),
      assignee: users(:one),
      title: "Done task",
      status: :done,
      priority: :normal
    )

    result = Demo::ActiveRecordFeatureDemo.query_probe(
      commented_task: tasks(:one),
      uncommented_task: uncommented,
      excluded_project: projects(:one)
    )

    assert_includes result[:associated_ids], tasks(:one).id
    assert_includes result[:missing_ids], uncommented.id
    refute_includes result[:excluding_ids], projects(:one).id
    refute_includes result[:without_ids], projects(:one).id
    assert_equal 0, result[:none_count]
    assert_equal [ tasks(:one).id, uncommented.id ].sort, result[:or_ids]
    assert_includes result[:and_ids], tasks(:one).id
    assert_includes result[:invert_where_ids], tasks(:one).id
    refute_includes result[:invert_where_ids], done_task.id
    assert_equal "urgent", result[:create_with_priority]
    assert_equal [ uncommented.id, tasks(:one).id ], result[:in_order_of_ids]
  end

  test "relation rewrite helpers and query annotations build SQL" do
    result = Demo::ActiveRecordFeatureDemo.rewrite_probe(commented_task: tasks(:one))

    assert_includes result[:reselect_sql], %("tasks"."id")
    assert_includes result[:rewhere_sql], %("tasks"."status" = 1)
    assert_equal false, result[:unscope_sql].include?("ORDER BY")
    assert_includes result[:regroup_sql], %("tasks"."priority")
    assert_includes result[:annotate_sql], "feature-probe"
  end

  test "sole helpers return the only matching row" do
    result = Demo::ActiveRecordFeatureDemo.sole_probe!(task: tasks(:one))

    assert_equal tasks(:one).id, result[:sole_id]
    assert_equal tasks(:one).id, result[:find_sole_by_id]
  end
end
