# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::ScrapeExecutor::Execute, type: :interactor do
  let(:token) { create(:token, :occupied) }
  let(:payload) { { url: 'https://www.example.com' }.to_json }
  let(:context) { { token_value: token.value, payload:, from_retry: } }

  let(:from_retry) { nil }
  let(:ctx) { described_class.call(context) }

  describe 'token' do
    context 'when from_retry different from incomplete_evaluation' do
      let(:from_retry) { nil }

      it 'increase token retries counter' do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(:failure)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(:success)
        expect(ctx.token.retries).to eq(1)
      end
    end

    context 'when from_retry is incomplete_evaluation' do
      let(:from_retry) { 'incomplete_evaluation' }

      it 'do not increase token retries counter' do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(:failure)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(:success)
        expect(ctx.token.retries).to eq(0)
      end
    end

    context 'when success' do
      before do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(:success)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(:success)
      end

      it 'consume token' do
        tkn = Token.find_by(value: ctx.token.value)
        expect(tkn).to be_nil
      end
    end

    context 'when fail perfom' do
      before do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(:failure)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(:success)
      end

      it 'not consume token' do
        tkn = Token.find_by(value: ctx.token.value)
        expect(tkn).to be_present
      end

      it 'do not free token' do
        tkn = Token.find_by(value: ctx.token.value)
        expect(tkn).not_to be_available
      end
    end

    context 'when fail callback' do
      before do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(:success)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(:failure)
      end

      it 'not consume token' do
        tkn = Token.find_by(value: ctx.token.value)
        expect(tkn).to be_present
      end

      it 'do not free token' do
        tkn = Token.find_by(value: ctx.token.value)
        expect(tkn).not_to be_available
      end
    end

    context 'when reach max retries' do
      before do
        token.update(retries: ENV.fetch('TOKEN_MAX_RETRIES').to_i)
      end

      it 'free token' do
        tkn = Token.find_by(value: ctx.token.value)
        expect(tkn).to be_available
      end
    end
  end

  describe 'retry' do
    context 'when success' do
      before do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(:success)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(:success)
      end

      it 'do not say to retry' do
        expect(ctx.success?).to be_truthy
        expect(ctx.retry_perform).to be_nil
      end
    end

    context 'when fail perfom' do
      before do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(:failure)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(:success)
      end

      it 'say to retry' do
        expect(ctx.success?).to be_falsey
        expect(ctx.retry_perform).to eq(:retry)
      end

      it 'increase token retries counter' do
        described_class.call(context)
        described_class.call(context)
        expect(token.reload.retries).to eq(2)
      end
    end

    context 'when fail callback' do
      before do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(:success)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(:failure)
      end

      it 'say to retry' do
        expect(ctx.success?).to be_falsey
        expect(ctx.retry_perform).to eq(:retry)
      end

      it 'increase token retries counter' do
        described_class.call(context)
        described_class.call(context)
        expect(token.reload.retries).to eq(2)
      end
    end

    context 'when scrape is evaluation incomplete' do
      before do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(:incomplete_evaluation)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(:success)
      end

      it 'say to retry' do
        expect(ctx.success?).to be_falsey
        expect(ctx.retry_perform).to eq(:retry_incomplete_evaluation)
      end
    end

    context 'when reach max retries' do
      before do
        token.update(retries: ENV.fetch('TOKEN_MAX_RETRIES').to_i)
      end

      it 'do not say to retry' do
        expect(ctx.success?).to be_truthy
        expect(ctx.retry_perform).to eq(:no_retry)
      end

      it 'perform is not called' do
        expect_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).not_to receive(:scrape)
        ctx
      end

      it 'callback is called' do
        expect_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback)
        ctx
      end
    end
  end
end
