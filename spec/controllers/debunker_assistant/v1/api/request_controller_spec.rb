# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DebunkerAssistant::V1::Api::RequestController, type: :controller do
  # Mock a index just to test the before actions
  controller do
    def index
      render json: { message: 'Hello, world!' }, status: :ok
    end
  end

  describe 'before actions' do
    it { is_expected.to use_before_action(:validate_params) }
  end

  describe 'GET #index' do
    let(:current_user) { build_stubbed(:user) }
    before do
      allow(DebunkerAssistant::V1::ApiAuthenticator::Organizer).to receive(:call) do
        double('Interactor::Context', success?: true, current_user:)
      end
    end

    context 'when the request is valid' do
      before do
        allow(DebunkerAssistant::V1::ParamsValidator::Organizer).to receive(:call) do
          double('Interactor::Context', success?: true)
        end
        get :index
      end

      it 'returns a successful response' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the request is invalid' do
      before do
        allow(DebunkerAssistant::V1::ParamsValidator::Organizer).to receive(:call) do
          double('Interactor::Context', success?: false, message: 'error', status: :bad_request)
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
  end
end
