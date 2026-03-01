require "csv"

class StreamsController < ApplicationController
  include ActionController::Live
  before_action :authenticate_user!

  def tasks
    send_stream filename: "tasks-live-#{Date.current}.csv", type: "text/csv" do |stream|
      stream.write("id,title,status\n")
      Task.order(:id).find_each do |task|
        stream.write(CSV.generate_line([ task.id, task.title, task.status ]))
      end
    end
  end
end
