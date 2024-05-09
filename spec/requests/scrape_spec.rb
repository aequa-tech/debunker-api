# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Scrape API', type: :request do
  let(:api_path) { '/api/v1/users/status' }
  let!(:user) { create(:user, :confirmed) }
  let!(:key_pair) { ApiKey.generate_key_pair }
  let!(:api_key) { create(:api_key, access_token: key_pair[:access_token], secret_token: key_pair[:secret_token], user:) }

  let(:valid_payload) do
    {
      url: 'https://www.test.com',
      analysisTypes: {
        evaluation: {
          callbackUrl: 'https://my-site.com/evaluation'
        }
      }
    }
  end

  let(:invalid_payload) { { url: 'invalid' } }
  let(:json) { JSON.parse(response.body) }

  describe 'POST /api/v1/scrape' do
    let(:api_path) { '/api/v1/scrape' }

    describe 'Status 200' do
      before do
        post api_path,
             params: valid_payload,
             headers: auth_headers(key_pair),
             as: :json
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'structure of the response is right' do
        expect(json.keys).to match_array(%w[message url])
      end

      it 'response headers are right' do
        response_headers_expetations(response)
      end
    end

    describe 'Status 401' do
      before do
        post api_path,
             headers: { 'X-API-Key' => 'invalid', 'X-API-Secret' => '' },
             as: :json
      end

      it 'returns status code 401' do
        expect(response).to have_http_status(401)
      end

      it 'structure of the response is right' do
        response_message_structure_expetations(json)
      end

      it 'response headers are right' do
        response_headers_expetations(response)
      end
    end

    describe 'Status 400' do
      context 'when AcceptLanguage is invalid' do
        before do
          post api_path,
               params: valid_payload,
               headers: auth_headers(key_pair).merge('Accept-Language' => 'invalid'),
               as: :json
        end

        it 'returns status code 400' do
          expect(response).to have_http_status(400)
        end

        it 'structure of the response is right' do
          response_message_structure_expetations(json)
        end

        it 'response headers are right' do
          response_headers_expetations(response)
        end
      end

      context 'when payload is invalid' do
        before do
          post api_path,
               params: invalid_payload,
               headers: auth_headers(key_pair),
               as: :json
        end

        it 'returns status code 400' do
          expect(response).to have_http_status(400)
        end

        it 'structure of the response is right' do
          response_message_structure_expetations(json)
        end

        it 'response headers are right' do
          response_headers_expetations(response)
        end
      end
    end

    describe 'Status 403' do
      before do
        api_key.tokens.destroy_all

        post api_path,
             params: valid_payload,
             headers: auth_headers(key_pair),
             as: :json
      end

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end

      it 'structure of the response is right' do
        response_message_structure_expetations(json)
      end

      it 'response headers are right' do
        response_headers_expetations(response)
      end
    end

    describe 'Status 429' do
      before do
        number_of_requests = ENV.fetch('RATE_LIMIT').to_i + 1
        number_of_requests.times do
          post api_path, params: invalid_payload, headers: auth_headers(key_pair)
        end
      end

      it 'returns status code 429' do
        expect(response).to have_http_status(429)
      end

      it 'structure of the response is right' do
        response_message_structure_expetations(json)
      end

      it 'response headers are right' do
        response_headers_expetations(response)
      end
    end
  end
end
