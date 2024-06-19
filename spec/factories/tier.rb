# frozen_string_literal: true

FactoryBot.define do
  factory :tier do
    name { 'Free' }
    tokens_rate { 10 }
    reload_rate_amount { 1 }
    reload_rate_unit { 'month' }
  end
end
