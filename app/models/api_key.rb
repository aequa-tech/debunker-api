# frozen_string_literal: true

class ApiKey < ActiveRecord::Base
  before_create :encode_secret
  after_create :manage_keys_and_tokens_creation
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

  def manage_keys_and_tokens_creation
    return TokenReloader.new(self).reload_tokens if user.api_keys.count == 1

    last_key = user.api_keys.active.order(created_at: :desc).last
    available_tokens_number = last_key.available_tokens.count
    reloaded_at = last_key.reloaded_at

    TokenReloader.new(self, force_tokens_rate: available_tokens_number).reload_tokens(force_reloaded_at: reloaded_at)
    expire_all!(except_ids: id)
  end

  def expire_all!(except_ids: nil)
    return self.class.where(user_id:).each(&:expire!) if except_ids.blank?

    self.class.where(user_id:).where.not(id: except_ids).each(&:expire!)
  end
end
