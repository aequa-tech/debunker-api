# frozen_string_literal: true

class ApiKey < ActiveRecord::Base
  before_create :encode_secret
  before_create :expire_all!
  after_create :generate_initial_call_tokens
  after_update :update_available_tokens_number

  belongs_to :user
  has_many :tokens, dependent: :destroy

  attr_writer :available_tokens_number

  validates :access_token, presence: true, uniqueness: true
  validates :secret_token, presence: true
  validates :user, presence: true

  scope :active, -> { where(expired_at: nil) }

  def self.usk(access_token, user)
    "#{access_token}%#{user.email}"
  end

  def self.authenticate!(access_token, secret)
    api_key = find_by(access_token:)
    return false if api_key.nil?
    return false if api_key.user.blank?
    return false if api_key.expired_at.present?

    decoded_secret = JWT.decode(api_key.secret_token, usk(access_token, api_key.user)).first
    decoded_secret == secret
  rescue JWT::DecodeError, JWT::VerificationError
    false
  end

  def self.generate_key_pair
    { access_token: SecureRandom.hex(32), secret_token: SecureRandom.hex(32) }
  end

  def encode_secret
    self.secret_token = JWT.encode(secret_token, ApiKey.usk(access_token, user))
    tokens.destroy_all
  end

  def masked_secret
    secret = JWT.decode(secret_token, ApiKey.usk(access_token, user)).first
    (secret[0..8] + ('*' * 8))[0..16]
  end

  def expire!
    update_columns(expired_at: Time.now)
    tokens.destroy_all
  end

  def expired?
    expired_at.present?
  end

  def available_tokens
    tokens.available
  end

  def next_reload_date
    reloaded_at + user.role.tier.reload_rate_period
  end

  private

  def update_available_tokens_number
    return unless @available_tokens_number

    TokenReloader.new(self, force_tokens_rate: @available_tokens_number)
                 .reload_tokens(update_reloaded_at: false)
  end

  def generate_initial_call_tokens
    TokenReloader.new(self).reload_tokens
  end

  def expire_all!
    self.class.where(user_id:).each(&:expire!)
  end
end
