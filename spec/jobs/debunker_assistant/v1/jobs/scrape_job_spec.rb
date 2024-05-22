# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

RSpec.describe DebunkerAssistant::V1::Jobs::ScrapeJob, type: :job do
  let(:payload) { 'payload' }
  let(:token_value) { 'token_value' }
  let(:result) { double('Result', retry_perform:) }

  before do
    allow(::DebunkerAssistant::V1::ScrapeExecutor::Organizer).to receive(:call).and_return(result)
  end

  describe '#perform' do
    subject { described_class.new.perform(payload, token_value) }

    context 'when retry_perform is :no_retry' do
      let(:retry_perform) { :no_retry }

      it 'does not requeue the job' do
        expect { subject }.not_to change(described_class.jobs, :size)
      end
    end

    context 'when retry_perform is :retry' do
      let(:retry_perform) { :retry }

      it 'requeues the job' do
        expect { subject }.to change(described_class.jobs, :size).by(1)
      end

      it 'is scheduled to run 30 seconds from now' do
        subject
        expect(described_class.jobs.first['at'].to_i).to eq(30.seconds.from_now.to_i)
      end
    end

    context 'when retry_perform is :retry_incomplete_evaluation' do
      let(:retry_perform) { :retry_incomplete_evaluation }

      it 'requeues the job' do
        expect { subject }.to change(described_class.jobs, :size).by(1)
      end

      it 'include incomplete_evaluation as arg' do
        subject
        expect(described_class.jobs.first['args']).to include('incomplete_evaluation')
      end

      it 'is scheduled to run 24 hours from now' do
        subject
        expect(described_class.jobs.first['at'].to_i).to eq(24.hours.from_now.to_i)
      end
    end
  end
end
