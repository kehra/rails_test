class SupportMailbox < ApplicationMailbox
  def process
    bounce_with InboundMailboxMailer.with(
      recipient: normalized_sender,
      subject: mail.subject.to_s
    ).support_bounce
  end

  private
    def normalized_sender
      mail.from&.first.to_s.strip.presence || "noreply@example.test"
    end
end
