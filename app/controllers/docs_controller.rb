class DocsController < ApplicationController
  before_action :authenticate_user!

  def preview
    render markdown: "# TeamHub API Notes\n\nThis page is rendered by `render markdown:`."
  end

  def debug_dump
    @payload = { rails: Rails.version, endpoint: "docs#debug_dump" }
  end

  def etag
    if stale?(etag: [ "teamhub-docs-etag-v1", current_user.id ], last_modified: Time.utc(2026, 2, 27))
      render plain: "etag-demo"
    end
  end

  def about
    render json: { name: "TeamHub", rails: Rails.version }
  end

  def feed
    @tasks = Task.order(updated_at: :desc).limit(5)
  end

  def files
    render plain: "file-path=#{params[:path]}"
  end
end
