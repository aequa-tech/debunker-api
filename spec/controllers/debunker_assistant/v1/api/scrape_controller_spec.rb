# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DebunkerAssistant::V1::Api::ScrapeController, type: :controller do
  let(:api_key) { create(:api_key) }
  let(:token) { create(:token, api_key:) }

  let(:expected_success_response) do
    {
      message: I18n.t('api.messages.scrape.queued'),
      url: 'http://example.com'
    }
  end

  let(:expected_error_response) do
    {
      message: 'error message'
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

  describe 'POST #create' do
    context 'when ScrapeQueuer::Organizer returns success' do
      before do
        allow(DebunkerAssistant::V1::ScrapeQueuer::Organizer).to receive(:call) do
          double('Interactor::Context', success?: true, url: 'http://example.com', token:)
        end
      end

      it 'returns a success response' do
        request.headers['X-API-Key'] = api_key.access_token
        post :create, body: 'payload'

        expect(response).to have_http_status(:ok)
        expect(response.body).to eq(expected_success_response.to_json)
      end
    end

    context 'when ScrapeQueuer::Organizer returns error' do
      before do
        allow(DebunkerAssistant::V1::ScrapeQueuer::Organizer).to receive(:call) do
          double('Interactor::Context', success?: false, message: 'error message', status: :internal_server_error)
        end
      end

      it 'returns an error response' do
        request.headers['X-API-Key'] = api_key.access_token
        post :create, body: 'payload'

        expect(response).to have_http_status(:internal_server_error)
        expect(response.body).to eq(expected_error_response.to_json)
      end

      it 'json response is correct' do
        request.headers['X-API-Key'] = api_key.access_token
        post :create, body: 'payload'

        expect(JSON.parse(response.body).keys).to eq(['message'])
        expect(JSON.parse(response.body)['message'].class).to eq(String)
      end
    end
  end
end
