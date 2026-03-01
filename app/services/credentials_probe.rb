class CredentialsProbe
  def self.teamhub_demo_flag
    Rails.application.credentials.dig(:teamhub, :demo_flag)
  end

  def self.raw_credentials_object
    Rails.application.credentials
  end
end
