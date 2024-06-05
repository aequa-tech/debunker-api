# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::Api::ScrapePerform, type: :model do
  let!(:user) { create(:user, :confirmed) }
  let!(:key_pair) { ApiKey.generate_key_pair }
  let!(:api_key) { create(:api_key, access_token: key_pair[:access_token], secret_token: key_pair[:secret_token], user: user) }
  let(:token_value) { api_key.available_tokens.first.value }

  let(:token) { Token.find_by(value: token_value) }
  let(:support_response_object) { JSON.parse(token.support_response_object) }
  let(:valid_payload) do
    {
      url: 'https://www.google.com',
      analysis_types: {
        evaluation: {
          callback_url: 'https://example.com/evaluation'
        },
        explanations: {
          callback_url: 'https://example.com/explanations',
          explanation_types: %w[explanationAffective explanationDanger explanationNetworkAnalysis]
        }
      },
      content_language: 'en',
      retry: true,
      max_retries: 3,
      timeout: 10,
      max_chars: 1000
    }
  end

  context 'when happy path' do
    let(:cassettes) do
      [
        { name: 'scrape_success' },
        { name: 'evaluation_success' },
        { name: 'explanation_affective_success' },
        { name: 'explanation_danger_success' },
        { name: 'explanation_network_success' }
      ]
    end

    describe '#scrape' do
      it 'store correctly information about scrape on support response object' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          expect(support_response_object['scrape']['request_id']).to be_present
        end
      end

      it 'store correctly information about evaluation' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape

          evaluation = support_response_object['evaluation']
          expect(evaluation['analysis_id']).to be_present
          expect(evaluation['data']).to be_present
          expect(evaluation['analysis_status']).to eq(200)
          expect(evaluation['callback_status']).to eq(0)
        end
      end

      it 'store correctly information about explanation affective' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape

          explanation = support_response_object['explanations']['data'].find { |explanation| explanation['explanationDim'] == 'explanationAffective' }
          expect(explanation['data']).to be_present
          expect(explanation['explanationDim']).to eq('explanationAffective')
          expect(explanation['status']).to eq(200)
        end
      end

      it 'store correctly information about explanation danger' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape

          explanation = support_response_object['explanations']['data'].find { |explanation| explanation['explanationDim'] == 'explanationDanger' }
          expect(explanation['data']).to be_present
          expect(explanation['explanationDim']).to eq('explanationDanger')
          expect(explanation['status']).to eq(200)
        end
      end

      it 'store correctly information about explanation network' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape

          explanation = support_response_object['explanations']['data'].find { |explanation| explanation['explanationDim'] == 'explanationNetworkAnalysis' }
          expect(explanation['data']).not_to be_present
          expect(explanation['explanationDim']).to eq('explanationNetworkAnalysis')
          expect(explanation['message']).to eq('Network analysis not yet implemented')
          expect(explanation['status']).to eq(501)
        end
      end
    end
  end

  context 'when scrape fails' do
    let(:cassettes) { [{ name: 'scrape_failure' }] }

    describe '#scrape' do
      it 'on support response object request_id is nil' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          expect(support_response_object['scrape']['request_id']).to be_nil
        end
      end

      it 'on support response object evaluation data is with errors' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          expect(support_response_object['evaluation']['data']).to be_present
          expect(support_response_object['evaluation']['data']['message']).to be_present
          expect(support_response_object['evaluation']['data']['status']).not_to eq(200)
          expect(support_response_object['evaluation']['analysis_status']).not_to eq(200)
          expect(support_response_object['evaluation']['callback_status']).to eq(0)
        end
      end

      it 'on support response object explanations data is with errors' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          expect(support_response_object['explanations']['data']).to be_present
          expect(support_response_object['explanations']['data'].count).to eq(3)
          expect(support_response_object['explanations']['analysis_status']).to eq(501)
          expect(support_response_object['explanations']['callback_status']).to eq(0)
        end
      end

      it 'on support response object explanation affective data is with errors' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          explanation = support_response_object['explanations']['data'].find { |explanation| explanation['explanationDim'] == 'explanationAffective' }
          expect(explanation['data']).not_to be_present
          expect(explanation['message']).to be_present
          expect(explanation['status']).not_to eq(200)
        end
      end

      it 'on support response object explanation danger data is with errors' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          explanation = support_response_object['explanations']['data'].find { |explanation| explanation['explanationDim'] == 'explanationDanger' }
          expect(explanation['data']).not_to be_present
          expect(explanation['message']).to be_present
          expect(explanation['status']).not_to eq(200)
        end
      end

      it 'on support response object explanation network data is with errors' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          explanation = support_response_object['explanations']['data'].find { |explanation| explanation['explanationDim'] == 'explanationNetworkAnalysis' }
          expect(explanation['data']).not_to be_present
          expect(explanation['explanationDim']).to eq('explanationNetworkAnalysis')
          expect(explanation['message']).to eq('Network analysis not yet implemented')
          expect(explanation['status']).to eq(501)
        end
      end
    end
  end

  context 'when evaluation fails' do
    let(:cassettes) do
      [
        { name: 'scrape_success' },
        { name: 'evaluation_failure' }
      ]
    end

    describe '#scrape' do
      it 'store correctly information about scrape on support response object' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          expect(support_response_object['scrape']['request_id']).to be_present
        end
      end

      it 'on support response object evaluation data is with errors' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          expect(support_response_object['evaluation']['data']).to be_present
          expect(support_response_object['evaluation']['data']['message']).to be_present
          expect(support_response_object['evaluation']['data']['status']).not_to eq(200)
          expect(support_response_object['evaluation']['analysis_status']).not_to eq(200)
          expect(support_response_object['evaluation']['callback_status']).to eq(0)
        end
      end

      it 'on support response object explanations data is with errors' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          expect(support_response_object['explanations']['data']).to be_present
          expect(support_response_object['explanations']['data'].count).to eq(3)
          expect(support_response_object['explanations']['analysis_status']).to eq(501)
          expect(support_response_object['explanations']['callback_status']).to eq(0)
        end
      end

      it 'on support response object explanation affective data is with errors' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          explanation = support_response_object['explanations']['data'].find { |explanation| explanation['explanationDim'] == 'explanationAffective' }
          expect(explanation['data']).not_to be_present
          expect(explanation['message']).to be_present
          expect(explanation['status']).not_to eq(200)
        end
      end

      it 'on support response object explanation danger data is with errors' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          explanation = support_response_object['explanations']['data'].find { |explanation| explanation['explanationDim'] == 'explanationDanger' }
          expect(explanation['data']).not_to be_present
          expect(explanation['message']).to be_present
          expect(explanation['status']).not_to eq(200)
        end
      end

      it 'on support response object explanation network data is with errors' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          explanation = support_response_object['explanations']['data'].find { |explanation| explanation['explanationDim'] == 'explanationNetworkAnalysis' }
          expect(explanation['data']).not_to be_present
          expect(explanation['explanationDim']).to eq('explanationNetworkAnalysis')
          expect(explanation['message']).to eq('Network analysis not yet implemented')
          expect(explanation['status']).to eq(501)
        end
      end
    end
  end

  context 'when explanation affective fails' do
    let(:cassettes) do
      [
        { name: 'scrape_success' },
        { name: 'evaluation_success' },
        { name: 'explanation_affective_failure' },
        { name: 'explanation_danger_success' },
        { name: 'explanation_network_success' }
      ]
    end

    describe '#scrape' do
      it 'store correctly information about scrape on support response object' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          expect(support_response_object['scrape']['request_id']).to be_present
        end
      end

      it 'store correctly information about evaluation' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape

          evaluation = support_response_object['evaluation']
          expect(evaluation['analysis_id']).to be_present
          expect(evaluation['data']).to be_present
          expect(evaluation['analysis_status']).to eq(200)
          expect(evaluation['callback_status']).to eq(0)
        end
      end

      it 'on support response object explanation affective data is with errors' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          explanation = support_response_object['explanations']['data'].find { |explanation| explanation['explanationDim'] == 'explanationAffective' }
          expect(explanation['data']).not_to be_present
          expect(explanation['message']).to be_present
          expect(explanation['status']).not_to eq(200)
        end
      end

      it 'store correctly information about explanation danger' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape

          explanation = support_response_object['explanations']['data'].find { |explanation| explanation['explanationDim'] == 'explanationDanger' }
          expect(explanation['data']).to be_present
          expect(explanation['explanationDim']).to eq('explanationDanger')
          expect(explanation['status']).to eq(200)
        end
      end

      it 'store correctly information about explanation network' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape

          explanation = support_response_object['explanations']['data'].find { |explanation| explanation['explanationDim'] == 'explanationNetworkAnalysis' }
          expect(explanation['data']).not_to be_present
          expect(explanation['explanationDim']).to eq('explanationNetworkAnalysis')
          expect(explanation['message']).to eq('Network analysis not yet implemented')
          expect(explanation['status']).to eq(501)
        end
      end
    end
  end

  context 'when explanation danger fails' do
    let(:cassettes) do
      [
        { name: 'scrape_success' },
        { name: 'evaluation_success' },
        { name: 'explanation_affective_success' },
        { name: 'explanation_danger_failure' },
        { name: 'explanation_network_success' }
      ]
    end

    describe '#scrape' do
      it 'store correctly information about scrape on support response object' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          expect(support_response_object['scrape']['request_id']).to be_present
        end
      end

      it 'store correctly information about evaluation' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape

          evaluation = support_response_object['evaluation']
          expect(evaluation['analysis_id']).to be_present
          expect(evaluation['data']).to be_present
          expect(evaluation['analysis_status']).to eq(200)
          expect(evaluation['callback_status']).to eq(0)
        end
      end

      it 'store correctly information about explanation affective' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape

          explanation = support_response_object['explanations']['data'].find { |explanation| explanation['explanationDim'] == 'explanationAffective' }
          expect(explanation['data']).to be_present
          expect(explanation['explanationDim']).to eq('explanationAffective')
          expect(explanation['status']).to eq(200)
        end
      end

      it 'on support response object explanation danger data is with errors' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape
          explanation = support_response_object['explanations']['data'].find { |explanation| explanation['explanationDim'] == 'explanationDanger' }
          expect(explanation['data']).not_to be_present
          expect(explanation['message']).to be_present
          expect(explanation['status']).not_to eq(200)
        end
      end

      it 'store correctly information about explanation network' do
        VCR.use_cassettes cassettes do
          described_class.new(valid_payload.to_json, token_value).scrape

          explanation = support_response_object['explanations']['data'].find { |explanation| explanation['explanationDim'] == 'explanationNetworkAnalysis' }
          expect(explanation['data']).not_to be_present
          expect(explanation['explanationDim']).to eq('explanationNetworkAnalysis')
          expect(explanation['message']).to eq('Network analysis not yet implemented')
          expect(explanation['status']).to eq(501)
        end
      end
    end
  end
end
