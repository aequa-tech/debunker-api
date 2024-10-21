# frozen_string_literal: true

FactoryBot.define do
  factory :token do
    value { Faker::Alphanumeric.alphanumeric(number: 32) }
    api_key { create(:api_key) }

    trait :occupied do
      used_on { 'https://example.com' }
    end

    trait :with_payload do
      payload_json do
        {
          url: 'https://www.test.com',
          analysisTypes: {
            evaluation: {
              callbackUrl: 'https://my-site.com/evaluation'
            },
            explanations: {
              callbackUrl: 'https://my-site.com/evaluations',
              explanationTypes: %w[explanationAffective explanationDanger]
            }
          }
        }.to_json
      end
    end

    trait :with_invalid_payload do
      payload_json do
        {
          url: 'https://www.test.com',
          analysisTypes: {}
        }.to_json
      end
    end

    trait :with_response do
      response_json do
        {
          scrape: { request_id: '123' },
          evaluation: { analysis_status: 200 },
          explanations: { analysis_status: 200 }
        }.to_json
      end
    end
  end
end
