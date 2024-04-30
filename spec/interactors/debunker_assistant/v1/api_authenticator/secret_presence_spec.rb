# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::ApiAuthenticator::SecretPresence, type: :interactor do
  context 'when the secret is present' do
    let(:context) { { request: double(headers: { 'X-API-Secret' => 'secret' }) } }

    it 'does not fail' do
      expect(described_class.call(context).success?).to be_truthy
    end
  end

  context 'when the secret is not present' do
    let(:context) { { request: double(headers: { 'X-API-Secret' => nil }) } }

    it 'fails' do
      expect(described_class.call(context).failure?).to be_truthy
      expect(described_class.call(context).message).to eq(I18n.t('api.messages.api_key.error.missings'))
      expect(described_class.call(context).status).to eq(:unauthorized)
    end
  end
end
