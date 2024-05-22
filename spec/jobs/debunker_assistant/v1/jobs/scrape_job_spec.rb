# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

RSpec.describe DebunkerAssistant::V1::Jobs::ScrapeJob, type: :job do
  let(:payload) { 'payload' }
  let(:token_value) { 'token_value' }
  let(:result) { double('Result', success?: success, retry_perform:) }

  before do
    allow(::DebunkerAssistant::V1::ScrapeExecutor::Organizer).to receive(:call).and_return(result)
  end

  describe '#perform' do
    subject { described_class.new.perform(payload, token_value) }

    context 'when the result is successful' do
      let(:success) { true }
      let(:retry_perform) { :no_retry }

      it 'does not requeue the job' do
        expect { subject }.not_to change(described_class.jobs, :size)
      end
    end

    context 'when the result is not successful but retry_perform is true' do
      let(:success) { false }
      let(:retry_perform) { :retry }

      it 'requeues the job' do
        expect { subject }.to change(described_class.jobs, :size).by(1)
      end
    end

    context 'when the result is not successful and retry_perform is false' do
      let(:success) { false }
      let(:retry_perform) { :no_retry }

      it 'does not requeue the job' do
        expect { subject }.not_to change(described_class.jobs, :size)
      end
    end
  end
end
