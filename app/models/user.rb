# frozen_string_literal: true

class User < ApplicationRecord
  has_many :api_keys, dependent: :destroy
  belongs_to :role

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  after_initialize :set_default_role, if: :new_record?

  def info_attributes
    attributes.slice('name', 'email').merge('role' => role.name)
  end

  def active_api_keys
    api_keys.active
  end

  def admin?
    role.role_type.to_sym == :admin
  end

  private

  def set_default_role
    self.role ||= Role.find_by(name: 'Basic', role_type: :user)
  end
end
