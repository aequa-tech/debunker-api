# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true

  before_create :generate_confirmation_token

  def info_attributes
    attributes.except('id', 'password_digest', 'confirmation_token', 'created_at',
                      'updated_at', 'confirmed_at', 'confirmation_sent_at')
  end

  def confirm
    if confirmed_at
      errors.add(:base, :already_confirmed)
      return false
    end

    store_confirmation
    generate_api_key
    save
  end

  private

  def generate_confirmation_token
    self.confirmation_token = SecureRandom.hex(16)
    self.confirmation_sent_at = Time.now
  end

  def generate_api_key
    self.api_key = SecureRandom.hex(10)
  end

  def store_confirmation
    self.confirmed_at = Time.now
    self.confirmation_token = nil
  end
end
