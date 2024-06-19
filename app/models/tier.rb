# frozen_string_literal: true

class Tier < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :tokens_rate, presence: true, numericality: { greater_than: 0 }
  validates :reload_rate_amount, presence: true, numericality: { greater_than: 0 }
  validates :reload_rate_unit, presence: true, inclusion: { in: %w[day week month] }

  has_many :roles, dependent: :nullify

  def reload_rate_period
    reload_rate_amount.send(reload_rate_unit)
  end

  def self.reload_active_keys
    ApiKey.active.each do |api_key|
      next unless api_key.next_reload_date < Date.today

      api_key.available_tokens_number = api_key.user&.role&.tier&.tokens_rate
      api_key.reloaded_at = Date.today
      api_key.save
    end
  end
end
