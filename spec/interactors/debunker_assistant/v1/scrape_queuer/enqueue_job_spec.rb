# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::ScrapeQueuer::EnqueueJob, type: :interactor do
  context 'when the job is enqueued' do
    let(:token) { create(:token) }
    let(:context) { { token_value: token.value, payload: { url: 'https://website.com' }.to_json } }

    it 'does not fail' do
      expect(described_class.call(context).success?).to be_truthy
    end

    it 'enqueues the job' do
      described_class.call(context)
      expect(::DebunkerAssistant::V1::Jobs::ScrapeJob).to have_enqueued_sidekiq_job(context[:payload], token.value)
    end
  end

  context 'when the job is not enqueued' do
    let(:token) { create(:token) }
    let(:context) { { token_value: token.value, payload: { url: 'https://example.com' }.to_json } }

    before { allow(::DebunkerAssistant::V1::Jobs::ScrapeJob).to receive(:perform_async).and_raise(StandardError) }

    it 'fails' do
      expect(described_class.call(context).failure?).to be_truthy
      expect(described_class.call(context).message).to eq(I18n.t('api.messages.errors.fatal'))
      expect(described_class.call(context).status).to eq(:internal_server_error)
    end

    it 'does not enqueue the job' do
      described_class.call(context)
      expect(::DebunkerAssistant::V1::Jobs::ScrapeJob).not_to have_enqueued_sidekiq_job(context[:payload], token.value)
    end
  end
end
