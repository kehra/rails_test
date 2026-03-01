class Demo::AdvancedProfile
  include ActiveModel::Model
  include ActiveModel::Dirty
  include ActiveModel::Callbacks
  include ActiveModel::Serializers::JSON

  define_model_callbacks :publish
  define_attribute_methods :name

  class Address
    include ActiveModel::Model

    attr_accessor :city

    validates :city, presence: true
  end

  class DomainValidator < ActiveModel::Validator
    def validate(record)
      return if record.email.to_s.end_with?("@example.test")

      record.errors.add(:email, "must use example.test")
    end
  end

  attr_reader :name
  attr_accessor :email, :status, :code, :nickname, :token, :password, :password_confirmation, :terms, :address

  validates :terms, acceptance: true
  validates :password, confirmation: true
  validates :name, length: { minimum: 3 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: %w[active archived] }
  validates :code, exclusion: { in: %w[BAD XXX] }
  validates :nickname, absence: true
  validate :address_must_be_valid
  validates_each :name do |record, attribute, value|
    record.errors.add(attribute, "cannot be reserved") if value.to_s.casecmp("admin").zero?
  end
  validates_with DomainValidator
  validates! :token, absence: true

  before_publish :mark_before_publish
  after_publish :mark_after_publish

  def initialize(attributes = {})
    super
    @address ||= Address.new
  end

  def name=(value)
    name_will_change! unless value == @name
    @name = value
  end

  def attributes
    {
      "name" => nil,
      "email" => nil,
      "status" => nil
    }
  end

  def publish
    run_callbacks :publish do
      @published = true
      changes_applied
    end
  end

  def published?
    @published == true
  end

  def before_publish_ran?
    @before_publish_ran == true
  end

  def after_publish_ran?
    @after_publish_ran == true
  end

  def persisted?
    false
  end

  def to_key
    nil
  end

  def to_param
    nil
  end

  private
    def mark_before_publish
      @before_publish_ran = true
    end

    def mark_after_publish
      @after_publish_ran = true
    end

    def address_must_be_valid
      return if address.blank? || address.valid?

      errors.add(:address, :invalid)
    end
end
