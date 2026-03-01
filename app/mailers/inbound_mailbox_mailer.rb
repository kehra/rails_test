class InboundMailboxMailer < ApplicationMailer
  def support_bounce
    mail(
      to: params[:recipient],
      subject: "[TeamHub] Support mailbox rejected",
      body: bounce_body("Support", params[:subject])
    )
  end

  def backstop_bounce
    mail(
      to: params[:recipient],
      subject: "[TeamHub] Mailbox rejected",
      body: bounce_body("Backstop", params[:subject])
    )
  end

  private
    def bounce_body(label, subject)
      "#{label} mailbox rejected inbound message: #{subject.presence || '(no subject)'}"
    end
end
