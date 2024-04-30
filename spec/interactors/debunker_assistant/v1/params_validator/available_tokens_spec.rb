# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::ParamsValidator::AvailableTokens, type: :interactor do
  context 'when the api key has available tokens' do
    let(:api_key) { create(:api_key) }
    let(:context) { { request: double(headers: { 'X-API-Key' => api_key.access_token }) } }

    it 'does not fail' do
      expect(described_class.call(context).success?).to be_truthy
    end
  end

  context 'when the api key has no available tokens' do
    let(:api_key) { create(:api_key) }
    let(:context) { { request: double(headers: { 'X-API-Key' => api_key.access_token }) } }

    before { api_key.tokens.update_all(used_on: 'https://www.website.web') }

    it 'fails' do
      expect(described_class.call(context).failure?).to be_truthy
      expect(described_class.call(context).message).to eq(I18n.t('api.messages.scrape.error.no_tokens'))
      expect(described_class.call(context).status).to eq(:forbidden)
    end
  end
end
