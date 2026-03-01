class SecurityTokenCodec
  PURPOSE = :teamhub_demo
  ENCRYPTOR_SALT = "teamhub_message_encryptor"

  def self.sign(payload)
    Rails.application.message_verifier(PURPOSE).generate(payload)
  end

  def self.verify(token)
    Rails.application.message_verifier(PURPOSE).verify(token)
  end

  def self.encrypt(payload)
    encryptor.encrypt_and_sign(payload)
  end

  def self.decrypt(token)
    encryptor.decrypt_and_verify(token)
  end

  def self.encryptor
    key_len = ActiveSupport::MessageEncryptor.key_len
    secret = Rails.application.key_generator.generate_key(ENCRYPTOR_SALT, key_len)
    ActiveSupport::MessageEncryptor.new(secret)
  end
end
