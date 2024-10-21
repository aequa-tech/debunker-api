# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::ScrapeExecutor::ValidPayload, type: :interactor do
  let(:context) { { token_value: token.value } }

  context 'when the payload is valid' do
    let(:token) { create(:token, :occupied, payload_json: { url: 'https://example.com' }.to_json) }
    before { allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePayload).to receive(:valid?).and_return(true) }

    it 'does not fail' do
      expect(described_class.call(context).success?).to be_truthy
    end
  end

  context 'when the payload is invalid' do
    let(:token) { create(:token, :occupied, payload_json: { url: 'invalid' }.to_json) }
    before { allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePayload).to receive(:valid?).and_return(false) }

    it 'fails' do
      expect(described_class.call(context).failure?).to be_truthy
      expect(described_class.call(context).retry_perform).to eq(:no_retry)
    end
  end
end
