class VipSupportRoute
  def match?(inbound_email)
    inbound_email.mail.recipients.map(&:downcase).include?("vip-help@example.test")
  end
end

class ApplicationMailbox < ActionMailbox::Base
  routing VipSupportRoute.new => :support
  routing "help@example.test" => :support
  routing "workflow@example.test" => :workflow
  routing "rescue@example.test" => :rescue_demo
  routing ->(inbound_email) { Array(inbound_email.mail.to).size > 1 } => :support
  routing /^tasks(\+\d+)?@/i => :tasks
  routing all: :backstop
end
