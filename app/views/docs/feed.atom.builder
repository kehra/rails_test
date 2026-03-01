atom_feed do |feed|
  feed.title("TeamHub Tasks")
  feed.updated(@tasks.first&.updated_at || Time.current)

  @tasks.each do |task|
    feed.entry(task) do |entry|
      entry.title(task.title)
      entry.updated(task.updated_at)
      entry.content(task.description.to_s, type: "html")
    end
  end
end
