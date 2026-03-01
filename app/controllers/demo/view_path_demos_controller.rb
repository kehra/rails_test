class Demo::ViewPathDemosController < ApplicationController
  prepend_view_path Rails.root.join("app/views/view_path_prepend")
  append_view_path Rails.root.join("app/views/view_path_append")

  def self.controller_path
    "view_path_demos"
  end

  def prepend_probe
  end

  def append_probe
  end
end
