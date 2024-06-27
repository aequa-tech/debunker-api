# frozen_string_literal: true

class TokenReloader
  include ActiveModel::Model

  attr_accessor :api_key, :user, :tier, :reload_rate_period, :tokens_rate, :next_reload_date

  validates :api_key, :user, :tier, presence: true

  def self.reload_active_keys
    ApiKey.active.each { |api_key| new(api_key).reload_tokens }
  end

  def initialize(api_key = nil, force_tokens_rate: nil)
    @api_key = api_key
    @user = api_key&.user
    @tier = @user&.role&.tier

    return unless @api_key.present?
    return unless @tier.present?

    @reload_rate_period = @tier.reload_rate_period
    @tokens_rate = force_tokens_rate.present? ? force_tokens_rate.to_i : @tier.tokens_rate.to_i
    @next_reload_date = api_key.reloaded_at + @reload_rate_period if @api_key.reloaded_at.present?
  end

  def reload_tokens(update_reloaded_at: true)
    return unless api_key_is_active
    return if update_reloaded_at && next_reload_date.present? && !next_reload_date_is_past

    update_available_tokens_number
    api_key.update_columns(reloaded_at: Date.today) if update_reloaded_at
  end

  private

  def api_key_is_active
    api_key.expired? ? false : true
  end

  def next_reload_date_is_past
    @next_reload_date.present? && @next_reload_date < Date.today ? true : false
  end

  def update_available_tokens_number
    return unless tokens_rate.present?

    current_tokens = api_key.tokens.count
    return if tokens_rate == current_tokens

    if tokens_rate > current_tokens
      add_tokens(tokens_rate - current_tokens)
    else
      remove_tokens(current_tokens - tokens_rate)
    end
  end

  def add_tokens(tokens_to_generate)
    generate_call_tokens(tokens_to_generate)
  end

  def remove_tokens(tokens_to_destroy)
    available_tokens.last(tokens_to_destroy).each(&:destroy)
  end

  def generate_call_tokens(count)
    count.times do
      token_created = false
      until token_created
        token = SecureRandom.hex(16)
        token_created = api_key.tokens.create(value: token)
      end
    end
  end
end
