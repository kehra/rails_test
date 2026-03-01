require "active_record/validations/associated"

class Demo::NormalizedAssociatedProfile
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Attributes::Normalization
  extend ActiveRecord::Validations::ClassMethods

  class Contact
    include ActiveModel::Model

    attr_accessor :email

    validates :email, presence: true
  end

  attribute :email, :string
  attr_accessor :contact

  normalizes :email, with: ->(value) { value.to_s.strip.downcase }
  validates_associated :contact

  def custom_validation_context?
    false
  end
end
