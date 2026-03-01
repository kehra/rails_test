class TaskMailer < ApplicationMailer
  before_action :set_payload
  before_deliver :attach_delivery_metadata
  after_deliver :emit_delivery_event

  def task_notification
    mail(
      to: @notification.user.email,
      cc: params[:cc],
      bcc: params[:bcc],
      reply_to: params[:reply_to],
      subject: "[TeamHub] #{@message}"
    )
  end

  private

  def set_payload
    @notification = Notification.find(params[:notification_id])
    payload = @notification.payload_hash
    @task = Task.find_by(id: payload["task_id"])
    @project = Project.find_by(id: payload["project_id"])
    @message = payload["message"]
  end

  def attach_delivery_metadata
    mail["X-TeamHub-Delivery"] = "task_notification"
    mail["X-TeamHub-Notification-ID"] = @notification.id.to_s if @notification
  end

  def emit_delivery_event
    Rails.event.notify("teamhub.mailer.delivered", mailer: self.class.name, message_id: mail.message_id)
  end
end
