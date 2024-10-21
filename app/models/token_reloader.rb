# frozen_string_literal: true

class TokenReloader
  class << self
    # Method called by scheduler
    def reload_active_keys
      ApiKey.active.each do |api_key|
        new(api_key).reload_tokens
        api_key.update_reload_date(date: Date.today)
      end
    end
  end

  def initialize(api_key)
    @api_key = api_key
    @user = @api_key&.user
    @tier = @user&.role&.tier
    return unless valid?

    @tokens_rate = @tier.tokens_rate.to_i
    @next_reload_date = @api_key.next_reload_date if @api_key.reloaded_at.present?
  end

  def reload_tokens
    return unless can_execute_operation?
    return unless next_reload_date_is_past

    adjust_available_tokens
  end

  def regenerate_single_token
    return unless can_execute_operation?

    generate_call_tokens(1)
  end

  private

  def valid?
    @api_key.present? && @user.present? && @tier.present?
  end

  def can_execute_operation?
    valid? && @next_reload_date.present? && @tokens_rate.present?
  end

  def next_reload_date_is_past
    (Date.today - @next_reload_date.to_date).to_i >= 0
  end

  def adjust_available_tokens
    return if @tokens_rate == @api_key.available_tokens.count

    if @tokens_rate > @api_key.available_tokens.count
      add_tokens(@tokens_rate - @api_key.available_tokens.count)
    else
      remove_tokens(@api_key.available_tokens.count - @tokens_rate)
    end
  end

  def add_tokens(amount)
    generate_call_tokens(amount)
  end

  def remove_tokens(amount)
    @api_key.available_tokens.last(amount).each(&:destroy)
  end

  def generate_call_tokens(amount)
    amount.times do
      @api_key.reload
      create_token_with_unique_value if @api_key.can_accept_new_token?
    end
  end

  def create_token_with_unique_value
    token_created = false
    until token_created
      token = @api_key.tokens.create(value: SecureRandom.hex(16))
      token_created = token.valid? && token.persisted?
    end
  end
end
