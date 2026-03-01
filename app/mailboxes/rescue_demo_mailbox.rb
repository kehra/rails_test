class RescueDemoMailbox < ApplicationMailbox
  rescue_from(StandardError) { bounced! }

  def process
    raise "rescue-demo"
  end
end
