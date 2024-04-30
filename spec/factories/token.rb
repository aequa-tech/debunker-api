# frozen_string_literal: true

FactoryBot.define do
  factory :token do
    value { Faker::Alphanumeric.alphanumeric(number: 32) }
    api_key { create(:api_key) }
  end

  trait :occupied do
    used_on { 'https://example.com' }
  end
end
