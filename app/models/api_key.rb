# frozen_string_literal: true

class ApiKey < ActiveRecord::Base
  before_create :encode_secret
  after_commit :manage_keys_and_tokens_creation, on: :create

  belongs_to :user
  has_many :tokens, dependent: :destroy

  validates :access_token, presence: true, uniqueness: true
  validates :secret_token, presence: true
  validates :user, presence: true

  scope :active, -> { where(expired_at: nil) }

  class << self
    def usk(access_token, user)
      "#{access_token}%#{user.email}"
    end

    def authenticate!(access_token, secret)
      api_key = find_by(access_token:)
      return false if api_key.blank?
      return false if api_key.user.blank?
      return false if api_key.expired?

      api_key.send(:unmasked_secret) == secret ? api_key.user : false
    rescue JWT::DecodeError, JWT::VerificationError
      false
    end

    def generate_key_pair
      { access_token: SecureRandom.hex(32), secret_token: SecureRandom.hex(32) }
    end
  end

  def masked_secret
    (unmasked_secret[0..8] + ('*' * 8))[0..16]
  end

  def expire!
    update_columns(expired_at: Time.zone.now)
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

  def can_accept_new_token?
    available_tokens.count < user.role.tier.tokens_rate
  end

  def update_reload_date(date:)
    update_columns(reloaded_at: date)
  end

  private

  def unmasked_secret
    JWT.decode(secret_token, ApiKey.usk(access_token, user)).first
  end

  def encode_secret
    self.secret_token = JWT.encode(secret_token, ApiKey.usk(access_token, user))
  end

  def manage_keys_and_tokens_creation
    if user.api_keys.count == 1
      update_reload_date(date: valid_reloadable_date)
      TokenReloader.new(self).reload_tokens
      update_reload_date(date: Date.today)
    else
      last_valid_key = user.active_api_keys.order(created_at: :desc).last
      update_reload_date(date: last_valid_key.reloaded_at || valid_reloadable_date)

      last_valid_key.available_tokens
                    .count
                    .times { TokenReloader.new(self).regenerate_single_token }
    end

    expire_all!(except_ids: id)
  end

  def expire_all!(except_ids: nil)
    return self.class.where(user_id:).each(&:expire!) if except_ids.blank?

    self.class.where(user_id:).where.not(id: except_ids).each(&:expire!)
  end

  def valid_reloadable_date
    (Date.yesterday - user.role.tier.reload_rate_period).to_date
  end
end
