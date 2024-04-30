# frozen_string_literal: true

RSpec.describe ::DebunkerAssistant::V1::ApiAuthenticator::Organizer, type: :interactor do
  context 'when key secret pair is a valid pair' do
    let(:context) { { request: double(headers: { 'X-API-Key' => 'key', 'X-API-Secret' => 'secret' }) } }

    before { allow(ApiKey).to receive(:authenticate!).and_return(true) }

    it 'does not fail' do
      expect(described_class.call(context).success?).to be_truthy
    end
  end

  context 'when the key is not present' do
    let(:context) { { request: double(headers: { 'X-API-Key' => nil, 'X-API-Secret' => 'secret' }) } }

    it 'fails' do
      expect(described_class.call(context).failure?).to be_truthy
      expect(described_class.call(context).message).to eq(I18n.t('api.messages.api_key.error.missings'))
      expect(described_class.call(context).status).to eq(:unauthorized)
    end
  end

  context 'when the secret is not present' do
    let(:context) { { request: double(headers: { 'X-API-Key' => 'key', 'X-API-Secret' => nil }) } }

    it 'fails' do
      expect(described_class.call(context).failure?).to be_truthy
      expect(described_class.call(context).message).to eq(I18n.t('api.messages.api_key.error.missings'))
      expect(described_class.call(context).status).to eq(:unauthorized)
    end
  end

  context 'when key secret pair is invalid' do
    let(:context) { { request: double(headers: { 'X-API-Key' => 'key', 'X-API-Secret' => 'secret' }) } }

    before { allow(ApiKey).to receive(:authenticate!).and_return(false) }

    it 'fails' do
      expect(described_class.call(context).failure?).to be_truthy
      expect(described_class.call(context).message).to eq(I18n.t('api.messages.api_key.error.unauthorized'))
      expect(described_class.call(context).status).to eq(:unauthorized)
    end
  end
end
