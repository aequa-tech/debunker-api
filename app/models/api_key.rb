# frozen_string_literal: true

class ApiKey < ActiveRecord::Base
  before_create :encode_secret
  after_create :generate_free_call_tokens

  belongs_to :user
  has_many :tokens, dependent: :destroy

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
    return false if api_key.user_id.nil?
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
  end

  def masked_secret
    secret = JWT.decode(secret_token, ApiKey.usk(access_token, user)).first
    (secret[0..8] + ('*' * 8))[0..16]
  end

  def expire!
    update_columns(expired_at: Time.now)
  end

  def expired?
    expired_at.present?
  end

  def available_tokens
    tokens.available
  end

  private

  def generate_call_tokens(count)
    count.times do
      token_created = false
      until token_created
        token = SecureRandom.hex(16)
        token_created = tokens.create(value: token)
      end
    end
  end

  def generate_free_call_tokens
    free = ENV.fetch('FREE_TOKENS_REGISTRATION').to_i
    generate_call_tokens(free)
  end

  def expire_all!
    self.class.where(user_id:).update_all(expired_at: Time.now)
  end
end
