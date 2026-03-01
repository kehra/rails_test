class TaskMailerInterceptor
  def self.delivering_email(message)
    return unless message.subject.to_s.start_with?("[TeamHub]")

    message.subject = "[Intercepted] #{message.subject}"
  end
end
