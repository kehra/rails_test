class InboundBounceMailer < ApplicationMailer
  def unknown_sender(address)
    mail(to: address.presence || "noreply@example.test", subject: "[TeamHub] Unknown sender", body: "Unknown sender address")
  end

  def project_not_found(address)
    mail(to: address.presence || "noreply@example.test", subject: "[TeamHub] Project not found", body: "Could not map inbound email to project")
  end
end
