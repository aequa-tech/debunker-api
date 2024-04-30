# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::ApiAuthenticator::KeyPresence, type: :interactor do
  context 'when key secret pair is a valid pair' do
    let(:context) { { request: double(headers: { 'X-API-Key' => 'key' }) } }

    it 'does not fail' do
      expect(described_class.call(context).success?).to be_truthy
    end
  end

  context 'when the key is not present' do
    let(:context) { { request: double(headers: { 'X-API-Key' => nil }) } }

    it 'fails' do
      expect(described_class.call(context).failure?).to be_truthy
      expect(described_class.call(context).message).to eq(I18n.t('api.messages.api_key.error.missings'))
      expect(described_class.call(context).status).to eq(:unauthorized)
    end
  end
end
