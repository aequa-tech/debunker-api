# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DebunkerAssistant::V1::Api::UsersController, type: :controller do
  let(:user) { create(:user) }
  let(:api_key) { create(:api_key, user:) }

  let(:expected_response) do
    {
      user: user.info_attributes,
      available_tokens: api_key.available_tokens.count
    }
  end

  before do
    allow(DebunkerAssistant::V1::ParamsValidator::AcceptLanguage).to receive(:call) do
      double('Interactor::Context', success?: true)
    end

    allow(DebunkerAssistant::V1::ApiAuthenticator::Organizer).to receive(:call) do
      double('Interactor::Context', success?: true)
    end

    allow(DebunkerAssistant::V1::ParamsValidator::Organizer).to receive(:call) do
      double('Interactor::Context', success?: true)
    end
  end

  describe 'GET #status' do
    it 'return user and tokens status connected to apikey' do
      request.headers['X-API-Key'] = api_key.access_token

      get :status

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(expected_response.to_json)
    end
  end
end
