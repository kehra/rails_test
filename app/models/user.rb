class User < ApplicationRecord
  has_secure_password
  encrypts :private_note
  has_one_attached :avatar

  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :comments, dependent: :destroy
  has_many :announcements, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :audit_logs, dependent: :nullify
  has_many :assigned_tasks, class_name: "Task", foreign_key: :assignee_id, dependent: :nullify, inverse_of: :assignee

  before_validation :normalize_email

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
