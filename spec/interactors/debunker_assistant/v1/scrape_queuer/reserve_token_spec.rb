# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::ScrapeQueuer::ReserveToken, type: :interactor do
  context 'when the token is valid and available' do
    let(:token) { create(:token) }
    let(:context) { { token_value: token.value, payload: { url: 'https://website.com' }.to_json } }

    it 'does not fail' do
      expect(described_class.call(context).success?).to be_truthy
    end

    it 'occupies the token' do
      described_class.call(context)
      token.reload
      expect(token.used_on).to eq('https://website.com')
    end
  end

  context 'when the token is not available' do
    let(:token) { create(:token, :occupied) }
    let(:context) { { token_value: token.value, payload: { url: 'https://example.com' } } }

    it 'fails' do
      expect(described_class.call(context).failure?).to be_truthy
      expect(described_class.call(context).message).to eq(I18n.t('api.messages.token.error.invalid'))
      expect(described_class.call(context).status).to eq(:internal_server_error)
    end
  end
end
