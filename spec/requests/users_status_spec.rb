# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Users Status', type: :request do
  let(:api_path) { '/api/v1/users/status' }
  let!(:user) { create(:user, :confirmed) }
  let!(:key_pair) { ApiKey.generate_key_pair }
  let!(:api_key) { create(:api_key, access_token: key_pair[:access_token], secret_token: key_pair[:secret_token], user:) }
  let(:json) { JSON.parse(response.body) }
  let(:rate_limit) { false }

  describe 'GET /users/status' do
    describe 'Status 200' do
      before { get api_path, headers: auth_headers(key_pair) }

      it 'returns the user' do
        expect(json).not_to be_empty
        expect(json['user']).not_to be_empty
        expect(json['user']['name']).to eq(user.name)
        expect(json['user']['email']).to eq(user.email)
        expect(json['user']['role']).to eq(user.role)
        expect(json['available_tokens']).to eq(api_key.available_tokens.count)
      end

      it 'structure of the response is right' do
        expect(json.keys).to match_array(%w[user available_tokens])
        expect(json['user'].keys).to match_array(%w[name email role])
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'response headers are right' do
        response_headers_expetations(response, rate_limit:)
      end
    end

    describe 'Status 401' do
      before { get api_path, headers: { 'X-API-Key' => 'invalid', 'X-API-Secret' => '' } }

      it 'returns status code 401' do
        expect(response).to have_http_status(401)
      end

      it 'structure of the response is right' do
        response_message_structure_expetations(json)
      end

      it 'response headers are right' do
        response_headers_expetations(response, rate_limit:)
      end
    end

    describe 'Status 400' do
      before do
        get api_path, headers: auth_headers(key_pair).merge('Accept-Language' => 'invalid')

        it 'returns status code 400' do
          expect(response).to have_http_status(400)
        end

        it 'structure of the response is right' do
          response_message_structure_expetations(json)
        end

        it 'response headers are right' do
          response_headers_expetations(response, rate_limit:)
        end
      end
    end
  end
end
