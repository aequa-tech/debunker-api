# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::ApiAuthenticator::Authenticate, type: :interactor do
  context 'when the key and secret are present' do
    let(:context) do
      { request: double(headers: { 'X-API-Key' => 'key', 'X-API-Secret' => 'secret' }) }
    end
    let(:result) { described_class.call(context) }
    let(:stubbed_user) { build_stubbed(:user) }

    before { allow(ApiKey).to receive(:authenticate!).and_return(stubbed_user) }

    it 'does not fail' do
      expect(result).to be_success
    end

    it 'puts the authenticate user in context' do
      expect(result.current_user).to be(stubbed_user)
    end
  end

  context 'when the key is not present' do
    let(:context) do
      { request: double(headers: { 'X-API-Key' => nil, 'X-API-Secret' => 'secret' }) }
    end

    it 'fails' do
      expect(described_class.call(context)).to be_failure
      expect(described_class.call(context).message).to eq(I18n.t('api.messages.api_key.error.unauthorized'))
      expect(described_class.call(context).status).to eq(:unauthorized)
    end
  end
end
