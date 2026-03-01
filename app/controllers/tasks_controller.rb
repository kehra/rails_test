require "csv"
require "tempfile"

class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: %i[ show edit update destroy purge_file purge_file_later ]

  # GET /tasks or /tasks.json
  def index
    @tasks = scoped_tasks.includes(:project, :assignee).order(created_at: :desc)
  end

  # GET /tasks/1 or /tasks/1.json
  def show
    nil unless stale?(@task)
  end

  # GET /tasks/export.csv
  def export
    tasks = scoped_tasks.includes(:project, :assignee).order(:id)
    csv = CSV.generate(headers: true) do |rows|
      rows << %w[id title project assignee status priority due_on]
      tasks.find_each do |task|
        rows << [
          task.id,
          task.title,
          task.project.name,
          task.assignee&.name,
          task.status,
          task.priority,
          task.due_on
        ]
      end
    end

    send_data csv, filename: "tasks-#{Date.current}.csv", type: "text/csv"
  end

  # GET /tasks/export_file.csv
  def export_file
    tasks = scoped_tasks.order(:id)
    file = Tempfile.new([ "tasks-", ".csv" ], binmode: true)
    file.write("id,title\n")
    tasks.find_each { |task| file.write("#{task.id},\"#{task.title.to_s.gsub('"', '""')}\"\n") }
    file.flush

    send_file file.path, filename: "tasks-file-#{Date.current}.csv", type: "text/csv", disposition: "attachment"
  ensure
    file&.close
  end

  # GET /tasks/new
  def new
    @task = Task.new(project_id: nested_project_id)
  end

  # GET /tasks/1/edit
  def edit
  end

  # POST /tasks or /tasks.json
  def create
    @task = Task.new(task_params_with_nested_context)

    respond_to do |format|
      if @task.save
        format.html { redirect_to @task, notice: "Task was successfully created." }
        format.json { render :show, status: :created, location: @task }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tasks/1 or /tasks/1.json
  def update
    updated = false

    respond_to do |format|
      Task.transaction do
        @task.with_lock { updated = @task.update(task_params) }
      end

      if updated
        format.html { redirect_to @task, notice: "Task was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @task }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tasks/1 or /tasks/1.json
  def destroy
    @task.destroy!

    respond_to do |format|
      format.html { redirect_to tasks_path, notice: "Task was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def purge_file
    attachment = @task.files_attachments.find_by!(blob_id: ActiveStorage::Blob.find_signed!(params.expect(:signed_id)).id)
    attachment.purge
    redirect_to @task, notice: "Attachment was purged."
  end

  def purge_file_later
    attachment = @task.files_attachments.find_by!(blob_id: ActiveStorage::Blob.find_signed!(params.expect(:signed_id)).id)
    attachment.purge_later
    redirect_to @task, notice: "Attachment purge was queued."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_task
      @task = scoped_tasks.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def task_params
      params.expect(task: [ :project_id, :assignee_id, :title, :description, :status, :priority, :due_on, :content, files: [], task_tags_attributes: [ :id, :name, :_destroy ] ])
    end

    def scoped_tasks
      relation = Task.joins(project: :organization).where(organizations: { id: current_user.organization_ids })
      return relation unless nested_project_id

      relation.where(project_id: nested_project_id)
    end

    def task_params_with_nested_context
      attrs = task_params
      attrs[:project_id] = nested_project_id if nested_project_id
      attrs
    end

    def nested_project_id
      params[:project_id].presence&.to_i
    end
end
