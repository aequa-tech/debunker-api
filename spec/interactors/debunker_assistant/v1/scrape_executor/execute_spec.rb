# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::ScrapeExecutor::Execute, type: :interactor do
  let(:token) { create(:token, :occupied) }
  let(:payload) { { url: 'https://www.example.com' }.to_json }
  let(:context) { { token_value: token.value, payload: } }

  let(:ctx) { described_class.call(context) }

  describe 'token' do
    it 'increase token retries counter' do
      expect(ctx.token.retries).to eq(1)
    end

    context 'when success' do
      before do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(true)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(true)
      end

      it 'consume token' do
        tkn = Token.find_by(value: ctx.token.value)
        expect(tkn).to be_nil
      end
    end

    context 'when fail perfom' do
      before do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(false)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(true)
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
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(true)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(false)
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
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(true)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(true)
      end

      it 'do not say to retry' do
        expect(ctx.success?).to be_truthy
        expect(ctx.retry_perform).to be_falsey
      end
    end

    context 'when fail perfom' do
      before do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(false)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(true)
      end

      it 'say to retry' do
        expect(ctx.success?).to be_falsey
        expect(ctx.retry_perform).to be_truthy
      end

      it 'increase token retries counter' do
        described_class.call(context)
        described_class.call(context)
        expect(token.reload.retries).to eq(2)
      end
    end

    context 'when fail callback' do
      before do
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapePerform).to receive(:scrape).and_return(true)
        allow_any_instance_of(::DebunkerAssistant::V1::Api::ScrapeCallback).to receive(:callback).and_return(false)
      end

      it 'say to retry' do
        expect(ctx.success?).to be_falsey
        expect(ctx.retry_perform).to be_truthy
      end

      it 'increase token retries counter' do
        described_class.call(context)
        described_class.call(context)
        expect(token.reload.retries).to eq(2)
      end
    end

    context 'when reach max retries' do
      before do
        token.update(retries: ENV.fetch('TOKEN_MAX_RETRIES').to_i)
      end

      it 'do not say to retry' do
        expect(ctx.success?).to be_truthy
        expect(ctx.retry_perform).to be_falsey
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
