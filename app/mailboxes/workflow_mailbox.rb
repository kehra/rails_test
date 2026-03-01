class WorkflowMailbox < ApplicationMailbox
  cattr_accessor :callback_log, default: []

  before_processing :mark_before
  around_processing :mark_around
  after_processing :mark_after

  def process
    self.class.callback_log << :process
  end

  private
    def mark_before
      self.class.callback_log << :before
    end

    def mark_after
      self.class.callback_log << :after
    end

    def mark_around
      self.class.callback_log << :around_before
      yield
      self.class.callback_log << :around_after
    end
end
