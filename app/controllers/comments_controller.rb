class CommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    task = scoped_tasks.find(params.expect(:task_id))
    comment = task.comments.create!(comment_params.merge(user: current_user))
    redirect_to task_path(task), notice: "Comment was successfully created."
  end

  def destroy
    comment = Comment.joins(task: { project: :organization }).where(organizations: { id: current_user.organization_ids }).find(params.expect(:id))
    task = comment.task
    comment.destroy!
    redirect_to task_path(task), notice: "Comment was successfully destroyed.", status: :see_other
  end

  private

  def comment_params
    params.expect(comment: [ :body ])
  end

  def scoped_tasks
    Task.joins(project: :organization).where(organizations: { id: current_user.organization_ids })
  end
end
