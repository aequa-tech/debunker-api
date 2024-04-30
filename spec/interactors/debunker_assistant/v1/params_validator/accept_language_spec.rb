# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::ParamsValidator::AcceptLanguage, type: :interactor do
  context 'when the accept language is valid' do
    let(:context) { { request: double(headers: { 'Accept-Language' => 'en' }) } }

    it 'does not fail' do
      expect(described_class.call(context).success?).to be_truthy
    end
  end

  context 'when the accept language is not present' do
    let(:context) { { request: double(headers: { 'Accept-Language' => nil }) } }

    it 'does not fail' do
      expect(described_class.call(context).success?).to be_truthy
    end
  end

  context 'when the accept language is invalid' do
    let(:context) { { request: double(headers: { 'Accept-Language' => 'invalid' }) } }

    it 'fails' do
      expect(described_class.call(context).failure?).to be_truthy
      expect(described_class.call(context).message).to eq(I18n.t('api.messages.locale.error.invalid'))
      expect(described_class.call(context).status).to eq(:bad_request)
    end
  end
end
