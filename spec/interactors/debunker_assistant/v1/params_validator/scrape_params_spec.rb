# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::ParamsValidator::ScrapeParams do
  context 'when valid payload' do
    let(:body) { StringIO.new }
    let(:context) { { request: double(body:) } }

    before do
      body.string = { url: 'https://example.com' }.to_json
      allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePayload).to receive(:valid?).and_return(true)
    end

    it 'does not fail' do
      expect(described_class.call(context).success?).to be_truthy
    end
  end

  context 'when invalid-json payload' do
    let(:body) { StringIO.new }
    let(:context) { { request: double(body:) } }
    let(:scrape_payload) { ::DebunkerAssistant::V1::Api::ScrapePayload.new({ url: 'invalid' }.to_json) }

    before do
      body.string = { url: 'invalid' }.to_json
      allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePayload).to receive(:valid?).and_return(false)
    end

    it 'fails' do
      expect(described_class.call(context).failure?).to be_truthy
      context[:request].body.rewind
      expect(described_class.call(context).message).to eq(scrape_payload.errors.full_messages.join(', '))
      context[:request].body.rewind
      expect(described_class.call(context).status).to eq(:bad_request)
    end
  end

  context 'when payload is a valid json but invalid' do
    let(:body) { StringIO.new }
    let(:context) { { request: double(body:) } }
    let(:scrape_payload) { ::DebunkerAssistant::V1::Api::ScrapePayload.new({ url: 'invalid' }.to_json) }

    before do
      body.string = { url: 'invalid' }.to_json
      scrape_payload.valid?
    end

    it 'fails' do
      expect(described_class.call(context).failure?).to be_truthy
      context[:request].body.rewind
      expect(described_class.call(context).message).to eq(scrape_payload.errors.full_messages.join(', '))
      context[:request].body.rewind
      expect(described_class.call(context).status).to eq(:bad_request)
    end
  end
end
