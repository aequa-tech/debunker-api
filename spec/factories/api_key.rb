# frozen_string_literal: true

FactoryBot.define do
  factory :api_key do
    access_token { SecureRandom.hex(32) }
    secret_token { SecureRandom.hex(32) }

    user { create(:user) }
  end
end
