# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::ApiAuthenticator::Authenticate, type: :interactor do
  context 'when the key and secret are present' do
    let(:context) do
      { request: double(headers: { 'X-API-Key' => 'key', 'X-API-Secret' => 'secret' }) }
    end

    before { allow(ApiKey).to receive(:authenticate!).and_return(true) }

    it 'does not fail' do
      expect(described_class.call(context).success?).to be_truthy
    end
  end

  context 'when the key is not present' do
    let(:context) do
      { request: double(headers: { 'X-API-Key' => nil, 'X-API-Secret' => 'secret' }) }
    end

    it 'fails' do
      expect(described_class.call(context).failure?).to be_truthy
      expect(described_class.call(context).message).to eq(I18n.t('api.messages.api_key.error.unauthorized'))
      expect(described_class.call(context).status).to eq(:unauthorized)
    end
  end
end
