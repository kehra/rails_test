class AdvancedMailerObserver
  cattr_accessor :delivered_subjects, default: []

  def self.delivered_email(message)
    self.delivered_subjects += [ message.subject.to_s ]
  end
end
