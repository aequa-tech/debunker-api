# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::ScrapeExecutor::Execute, type: :interactor do
  let(:payload) { { url: 'https://www.example.com' }.to_json }
  let(:token) { create(:token, :occupied, payload_json: payload) }
  let(:context) { { token_value: token.value, from_retry: } }

  let(:from_retry) { nil }
  let(:ctx) { described_class.call(context) }

  describe 'token' do
    it 'increase token retries counters' do
      allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(:success)
      allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(:success)
      expect(ctx.token.perform_retries).to eq(1)
      expect(ctx.token.callback_retries).to eq(1)
    end

    context 'when success' do
      before do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(:success)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(:success)
      end

      it 'finish token' do
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
      let(:token_count) { Token.available.count }

      before do
        token
        token_count
        token.update(perform_retries: ENV.fetch('TOKEN_MAX_RETRIES').to_i)
        token.update(callback_retries: ENV.fetch('TOKEN_MAX_RETRIES').to_i)
      end

      it 'finish token - Regenerate another token' do
        tkn = Token.find_by(value: ctx.token.value)
        expect(tkn).to be_nil
        expect(Token.available.count).to eq(token_count)
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
        expect(ctx.retry_perform).to eq(:no_retry)
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
        expect(token.reload.perform_retries).to eq(2)
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
        expect(token.reload.callback_retries).to eq(2)
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

    context 'when reach max perform retries' do
      before do
        token.update(perform_retries: ENV.fetch('TOKEN_MAX_RETRIES').to_i)
      end

      it 'perform is not called' do
        expect_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).not_to receive(:scrape)
        ctx
      end
    end

    context 'when reach max callback retries' do
      before do
        token.update(callback_retries: ENV.fetch('TOKEN_MAX_RETRIES').to_i)
      end

      it 'callback is called' do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(:incomplete_evaluation)
        expect_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).not_to receive(:callback)
        ctx
      end
    end

    context 'when reach max retries during last iteration' do
      before do
        token.update(perform_retries: ENV.fetch('TOKEN_MAX_RETRIES').to_i - 1)
        token.update(callback_retries: ENV.fetch('TOKEN_MAX_RETRIES').to_i - 1)
      end

      it 'say to no retry' do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(:success)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(:failure)
        expect(ctx.success?).to be_truthy
        expect(ctx.retry_perform).to eq(:no_retry)
      end
    end
  end
end
