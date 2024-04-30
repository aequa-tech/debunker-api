# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DebunkerAssistant::V1::Api::AuthenticatedController, type: :controller do
  # Mock a index just to test the before actions
  controller do
    def index
      render json: { message: 'Hello, world!' }, status: :ok
    end
  end

  describe 'before actions' do
    it { is_expected.to use_before_action(:validate_locale) }
    it { is_expected.to use_before_action(:set_locale) }
    it { is_expected.to use_before_action(:authenticate!) }
  end

  describe 'GET #index' do
    context 'when the request is valid' do
      before do
        allow(DebunkerAssistant::V1::ParamsValidator::AcceptLanguage).to receive(:call) do
          double('Interactor::Context', success?: true)
        end

        allow(DebunkerAssistant::V1::ApiAuthenticator::Organizer).to receive(:call) do
          double('Interactor::Context', success?: true)
        end
        get :index
      end

      it 'returns a successful response' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when AcceptLanguage is invalid' do
      before do
        allow(DebunkerAssistant::V1::ParamsValidator::AcceptLanguage).to receive(:call) do
          double('Interactor::Context', success?: false, message: 'Error message', status: :bad_request)
        end
        get :index
      end

      it 'returns an error response' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'json response is correct' do
        expect(JSON.parse(response.body).keys).to eq(['message'])
        expect(JSON.parse(response.body)['message'].class).to eq(String)
      end
    end

    context 'when ApiAuthenticator is invalid' do
      before do
        allow(DebunkerAssistant::V1::ParamsValidator::AcceptLanguage).to receive(:call) do
          double('Interactor::Context', success?: true)
        end

        allow(DebunkerAssistant::V1::ApiAuthenticator::Organizer).to receive(:call) do
          double('Interactor::Context', success?: false, message: 'Error message', status: :unauthorized)
        end
        get :index
      end

      it 'returns an error response' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'json response is correct' do
        expect(JSON.parse(response.body).keys).to eq(['message'])
        expect(JSON.parse(response.body)['message'].class).to eq(String)
      end
    end
  end
end
