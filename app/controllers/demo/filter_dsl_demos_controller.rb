class Demo::FilterDslDemosController < ActionController::Base
  prepend_before_action :prepend_before_marker
  before_action :before_marker
  append_before_action :append_before_marker

  prepend_after_action :prepend_after_marker
  after_action :after_marker
  append_after_action :append_after_marker

  prepend_around_action :prepend_around_marker
  around_action :around_marker
  append_around_action :append_around_marker

  def show
    filter_log << "action"
    render plain: filter_log.join(">")
  end

  private
    def filter_log
      request.env["teamhub.filter_log"] ||= []
    end

    def prepend_before_marker
      filter_log << "prepend_before"
    end

    def before_marker
      filter_log << "before"
    end

    def append_before_marker
      filter_log << "append_before"
    end

    def prepend_after_marker
      filter_log << "prepend_after"
    end

    def after_marker
      filter_log << "after"
    end

    def append_after_marker
      filter_log << "append_after"
      response.set_header("X-Filter-Order", filter_log.join(">"))
    end

    def prepend_around_marker
      filter_log << "prepend_around_before"
      yield
      filter_log << "prepend_around_after"
    end

    def around_marker
      filter_log << "around_before"
      yield
      filter_log << "around_after"
    end

    def append_around_marker
      filter_log << "append_around_before"
      yield
      filter_log << "append_around_after"
    end
end
