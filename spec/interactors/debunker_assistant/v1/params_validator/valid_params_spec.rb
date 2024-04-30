# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DebunkerAssistant::V1::ParamsValidator::ValidParams do
  context 'when request path is /users/status' do
    let(:context) { { request: double({ path: '/users/status' }) } }

    context 'when the request is valid' do
      before do
        allow(DebunkerAssistant::V1::ParamsValidator::UsersStatusParams).to receive(:call) do
          double('Interactor::Context', success?: true)
        end
      end

      it 'does not fail' do
        expect(described_class.call(context).success?).to be_truthy
      end
    end

    context 'when the request is invalid' do
      before do
        allow(DebunkerAssistant::V1::ParamsValidator::UsersStatusParams).to receive(:call) do
          double('Interactor::Context', success?: false, message: 'error', status: :bad_request)
        end
      end

      it 'fails' do
        expect(described_class.call(context).failure?).to be_truthy
        expect(described_class.call(context).message).to eq('error')
        expect(described_class.call(context).status).to eq(:bad_request)
      end
    end
  end

  context 'when request path is /scrape' do
    let(:context) { { request: double({ path: '/scrape' }) } }

    context 'when the request is valid' do
      before do
        allow(DebunkerAssistant::V1::ParamsValidator::ScrapeParams).to receive(:call) do
          double('Interactor::Context', success?: true)
        end

        allow(DebunkerAssistant::V1::ApiAuthenticator::Organizer).to receive(:call) do
          double('Interactor::Context', success?: true)
        end

        allow(DebunkerAssistant::V1::ParamsValidator::AvailableTokens).to receive(:call) do
          double('Interactor::Context', success?: true)
        end
      end

      it 'does not fail' do
        expect(described_class.call(context).success?).to be_truthy
      end
    end

    context 'when ScrapeParams fails' do
      before do
        allow(DebunkerAssistant::V1::ParamsValidator::ScrapeParams).to receive(:call) do
          double('Interactor::Context', success?: false, message: 'scrape error', status: :bad_request)
        end

        allow(DebunkerAssistant::V1::ApiAuthenticator::Organizer).to receive(:call) do
          double('Interactor::Context', success?: true)
        end

        allow(DebunkerAssistant::V1::ParamsValidator::AvailableTokens).to receive(:call) do
          double('Interactor::Context', success?: true)
        end
      end

      it 'fails' do
        expect(described_class.call(context).failure?).to be_truthy
        expect(described_class.call(context).message).to eq('scrape error')
        expect(described_class.call(context).status).to eq(:bad_request)
      end
    end

    context 'when ApiAuthenticator organizer fails' do
      before do
        allow(DebunkerAssistant::V1::ParamsValidator::ScrapeParams).to receive(:call) do
          double('Interactor::Context', success?: true)
        end

        allow(DebunkerAssistant::V1::ApiAuthenticator::Organizer).to receive(:call) do
          double('Interactor::Context', success?: false, message: 'auth error', status: :unauthorized)
        end

        allow(DebunkerAssistant::V1::ParamsValidator::AvailableTokens).to receive(:call) do
          double('Interactor::Context', success?: true)
        end
      end

      it 'fails' do
        expect(described_class.call(context).failure?).to be_truthy
        expect(described_class.call(context).message).to eq('auth error')
        expect(described_class.call(context).status).to eq(:unauthorized)
      end
    end

    context 'when AvailableTokens  fails' do
      before do
        allow(DebunkerAssistant::V1::ParamsValidator::ScrapeParams).to receive(:call) do
          double('Interactor::Context', success?: true)
        end

        allow(DebunkerAssistant::V1::ApiAuthenticator::Organizer).to receive(:call) do
          double('Interactor::Context', success?: true)
        end

        allow(DebunkerAssistant::V1::ParamsValidator::AvailableTokens).to receive(:call) do
          double('Interactor::Context', success?: false, message: 'tokens error', status: :forbidden)
        end
      end

      it 'fails' do
        expect(described_class.call(context).failure?).to be_truthy
        expect(described_class.call(context).message).to eq('tokens error')
        expect(described_class.call(context).status).to eq(:forbidden)
      end
    end
  end
end
