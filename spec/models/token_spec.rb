# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Token, type: :model do
  let(:api_key) { create(:api_key) }
  let(:token) { api_key.available_tokens.first }
  let(:valid_payload) do
    {
      url: 'https://www.google.com',
      analysis_types: {
        evaluation: {
          callback_url: 'https://example.com/evaluation'
        },
        explanations: {
          callback_url: 'https://example.com/explanations',
          explanation_types: %w[explanationAffective explanationDanger explanationNetworkAnalysis]
        }
      },
      content_language: 'en',
      retry: true,
      max_retries: 3,
      timeout: 10,
      max_chars: 1000
    }
  end


  describe 'associations' do
    it { should belong_to(:api_key) }
  end

  describe 'validations' do
    it { should validate_presence_of(:value) }
    it 'value is unique' do
      create(:token, value: '123', api_key:)
      token = build(:token, value: '123', api_key: create(:api_key))
      expect(token).not_to be_valid
    end
  end

  describe 'available' do
    it 'returns available tokens' do
      expect(Token.available).to include(token)
    end
  end

  describe '#available?' do
    it 'returns true if the token is available' do
      expect(token.available?).to be_truthy
    end
  end

  describe '#occupy!' do
    it 'updates the token' do
      token.occupy!(::DebunkerAssistant::V1::Api::ScrapePayload.new(valid_payload.to_json))
      expect(token.used_on).to eq('https://www.google.com')
      expect(token.perform_status).to eq('in_progress')
      expect(token.callback_status).to eq('initial')
      expect(token.payload_json).to eq(valid_payload.to_json)
      expect(token.response_json).to eq(token.response_object.to_json)
    end
  end

  describe '#status!' do
    it 'updates the perform_status' do
      token.status!(:success, kind: :perform)
      expect(token.perform_status).to eq('success')
    end

    it 'updates the callback_status' do
      token.status!(:success, kind: :callback)
      expect(token.callback_status).to eq('success')
    end
  end

  describe '#increase_retries!' do
    it 'increases the perform_retries' do
      token.increase_retries!(kind: :perform)
      expect(token.perform_retries).to eq(1)
    end

    it 'increases the callback_retries' do
      token.increase_retries!(kind: :callback)
      expect(token.callback_retries).to eq(1)
    end
  end

  describe '#persist!' do
    it 'updates the response_json' do
      token.persist!({ 'type' => { callback_status: 201 } }, kind: :response)
      expect(token.response_json).to eq({ 'type' => { callback_status: 201 } }.to_json)
    end

    it 'updates the payload_json' do
      token.persist!({ 'type' => { callback_status: 201 } }, kind: :payload)
      expect(token.payload_json).to eq({ 'type' => { callback_status: 201 } }.to_json)
    end
  end

  describe '#finish!' do
    it 'updates the perform_status and callback_status' do
      token.finish!
      expect(token.perform_status).to eq(token.scrape_outcome.to_s)
      expect(token.callback_status).to eq(token.callback_outcome.to_s)
    end

    it 'regenerates the token' do
      token.update(used_on: 'https://www.google.com')
      expect(api_key.available_tokens.count).to eq(api_key.user.role.tier.tokens_rate - 1)
      allow_any_instance_of(Token).to receive(:scrape_outcome).and_return(:failure)
      allow_any_instance_of(Token).to receive(:callback_outcome).and_return(:invalid)
      token.finish!
      expect(api_key.available_tokens.count).to eq(api_key.user.role.tier.tokens_rate)
    end
  end

  describe '#response_object' do
    it 'returns standard the response object when response_json is empty' do
      expect(token.response_object).to eq({
                                            scrape: { request_id: nil },
                                            evaluation: { analysis_id: nil, data: {}, analysis_status: 0,
                                                          callback_status: 0 },
                                            explanations: { data: [], analysis_status: 0, callback_status: 0 }
                                          })
    end

    it 'returns the response object' do
      token.update(response_json: { scrape: { request_id: 1 } }.to_json)
      expect(token.response_object).to eq({ scrape: { request_id: 1 } })
    end
  end

  describe '#scrape_outcome' do
    let(:token) { create(:token, :with_payload, api_key:) }

    it 'returns failure when request_id is empty' do
      expect(token.scrape_outcome).to eq(:failure)
    end

    it 'returns incomplete_evaluation when analysis_status is incomplete' do
      token.update(response_json: { scrape: { request_id: 1 }, evaluation: { analysis_status: 206 },
                                    explanations: { analysis_status: 500 } }.to_json)
      expect(token.scrape_outcome).to eq(:incomplete_evaluation)
    end

    it 'returns success when all analysis types are successful' do
      token.update(response_json: { scrape: { request_id: 1 }, evaluation: { analysis_status: 200 },
                                    explanations: { analysis_status: 200 } }.to_json)
      expect(token.scrape_outcome).to eq(:success)
    end

    it 'returns partial when some analysis types are successful' do
      token.update(response_json: { scrape: { request_id: 1 }, evaluation: { analysis_status: 200 },
                                    explanations: { analysis_status: 500 } }.to_json)
      expect(token.scrape_outcome).to eq(:partial)
    end

    it 'returns failure when all analysis types are failed' do
      token.update(response_json: { scrape: { request_id: 1 }, evaluation: { analysis_status: 500 },
                                    explanations: { analysis_status: 500 } }.to_json)
      expect(token.scrape_outcome).to eq(:failure)
    end

    it 'returns invalid when analysis types are empty' do
      token = create(:token, :with_invalid_payload, api_key:)
      token.update(response_json: { scrape: { request_id: 1 } }.to_json)
      expect(token.scrape_outcome).to eq(:invalid)
    end
  end

  describe '#callback_outcome' do
    let(:token) { create(:token, :with_payload, api_key:) }

    it 'returns failure when request_id is empty' do
      expect(token.callback_outcome).to eq(:failure)
    end

    it 'returns success when all analysis types are successful' do
      token.update(response_json: { scrape: { request_id: 1 }, evaluation: { callback_status: 200 },
                                    explanations: { callback_status: 200 } }.to_json)
      expect(token.callback_outcome).to eq(:success)
    end

    it 'returns partial when some analysis types are successful' do
      token.update(response_json: { scrape: { request_id: 1 }, evaluation: { callback_status: 200 },
                                    explanations: { callback_status: 500 } }.to_json)
      expect(token.callback_outcome).to eq(:partial)
    end

    it 'returns failure when all analysis types are failed' do
      token.update(response_json: { scrape: { request_id: 1 }, evaluation: { callback_status: 500 },
                                    explanations: { callback_status: 500 } }.to_json)
      expect(token.callback_outcome).to eq(:failure)
    end

    it 'returns invalid when analysis types are empty' do
      token = create(:token, :with_invalid_payload, api_key:)
      token.update(response_json: { scrape: { request_id: 1 } }.to_json)
      expect(token.callback_outcome).to eq(:invalid)
    end
  end
end
