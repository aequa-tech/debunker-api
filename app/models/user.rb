# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  has_many :tokens, dependent: :destroy

  validates :email, presence: true, uniqueness: true

  before_create :generate_confirmation_token

  def info_attributes
    attributes.except('id', 'password_digest', 'confirmation_token', 'created_at',
                      'updated_at', 'confirmed_at', 'confirmation_sent_at')
  end

  def generate_call_tokens(count)
    count.times do
      token_created = false
      until token_created
        token = SecureRandom.hex(16)
        token_created = tokens.create(value: token)
      end
    end
  end

  def confirm
    if confirmed_at
      errors.add(:base, :already_confirmed)
      return false
    end

    store_confirmation
    generate_api_key
    saved = save
    generate_free_call_tokens if saved

    saved
  end

  private

  def generate_confirmation_token
    self.confirmation_token = SecureRandom.hex(16)
    self.confirmation_sent_at = Time.now
  end

  def generate_api_key
    self.api_key = SecureRandom.hex(16)
  end

  def generate_free_call_tokens
    free = ENV.fetch('FREE_TOKENS_REGISTRATION').to_i
    generate_call_tokens(free)
  end

  def store_confirmation
    self.confirmed_at = Time.now
    self.confirmation_token = nil
  end
end
