class AdvancedMailerRuntimeInterceptor
  def self.delivering_email(message)
    message["X-Registry-Interceptor"] = "registered"
  end
end
