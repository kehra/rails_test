class TasksMailbox < ApplicationMailbox
  def process
    sender = User.find_by(email: normalized_sender)
    return bounced! unless sender

    project = find_project_for(sender)
    return bounced! unless project

    body = extracted_body
    attachment_summary = extracted_attachment_summary
    task = project.tasks.create!(
      title: normalized_subject,
      description: [ body, attachment_summary ].compact.join("\n").truncate(500),
      assignee: sender,
      status: :todo,
      priority: :normal
    )
    task.update!(content: [ body, attachment_summary ].compact.join("\n")) if body.present? || attachment_summary.present?
  end

  private

  def normalized_sender
    mail.from&.first.to_s.strip.downcase
  end

  def normalized_subject
    mail.subject.to_s.strip.presence || "Task from email"
  end

  def extracted_body
    mail.text_part&.decoded.to_s.strip.presence || mail.body.decoded.to_s.strip
  end

  def extracted_attachment_summary
    return if mail.attachments.blank?

    "Attachments: #{mail.attachments.map(&:filename).map(&:to_s).join(', ')}"
  end

  def find_project_for(sender)
    project_id = recipient_project_id
    return sender_accessible_projects(sender).find_by(id: project_id) if project_id

    sender_accessible_projects(sender).active.first
  end

  def sender_accessible_projects(sender)
    Project.joins(:organization).where(organizations: { id: sender.organization_ids })
  end

  def recipient_project_id
    recipient = Array(mail.to).find { |addr| addr.to_s.downcase.include?("tasks+") }
    return unless recipient

    match = recipient.to_s.match(/tasks\+(\d+)@/i)
    match[1].to_i if match
  end
end
