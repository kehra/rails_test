class AdvancedMailerPreviewInterceptor
  def self.previewing_email(message)
    message["X-Preview-Intercepted"] = "true"
  end
end
