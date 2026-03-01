class AdvancedMailerPreview < ActionMailer::Preview
  def digest_report
    AdvancedMailer.with(
      recipient: "preview@example.test",
      recipient_name: "Preview User",
      project: Project.first || Project.new(id: 1),
      trace: "preview-trace"
    ).digest_report
  end
end
