Rails.application.configure do
  config.active_record.encryption.primary_key = ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY", "0123456789abcdef0123456789abcdef")
  config.active_record.encryption.deterministic_key = ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY", "abcdef0123456789abcdef0123456789")
  config.active_record.encryption.key_derivation_salt = ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT", "salt0123456789salt0123456789")
end
