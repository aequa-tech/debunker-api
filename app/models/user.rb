# frozen_string_literal: true

class User < ApplicationRecord
  has_many :api_keys, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  enum role: %i[user admin]

  after_initialize :set_default_role, if: :new_record?

  def info_attributes
    attributes.slice('name', 'email', 'api_key', 'role')
  end

  def active_api_keys
    api_keys.active
  end

  private

  def set_default_role
    self.role ||= :user
  end
end
