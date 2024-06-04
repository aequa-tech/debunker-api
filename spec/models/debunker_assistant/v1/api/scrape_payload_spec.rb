# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::DebunkerAssistant::V1::Api::ScrapePayload, type: :model do
  let(:valid_payload) do
    {
      url: 'https://example.com',
      analysis_types: {
        evaluation: {
          callback_url: 'https://example.com/evaluation'
        },
        explanations: {
          callback_url: 'https://example.com/explanations',
          explanation_types: ['affectiveStyle']
        }
      },
      content_language: 'en',
      retry: true,
      max_retries: 3,
      timeout: 10,
      max_chars: 1000
    }
  end

  let(:invalid_json) do
    "{ url: 'https://example.com', {} }"
  end

  let(:scrape_payload) { described_class.new(valid_payload.to_json) }

  context 'when the payload is a valid json' do
    it 'invalid_json error is not added' do
      expect(scrape_payload.errors.added?(:base, :invalid_json)).to be_falsey
    end
  end

  context 'when the payload is an invalid json' do
    let(:invalid_scrape_payload) { described_class.new(invalid_json) }

    it 'invalid_json error is added' do
      expect(invalid_scrape_payload.errors.added?(:base, :invalid_json)).to be_truthy
    end
  end

  describe '#initialize' do
    it 'creates a new instance of the class' do
      expect(scrape_payload).to be_an_instance_of(DebunkerAssistant::V1::Api::ScrapePayload)
    end
  end

  describe '#url_validation' do
    context 'when the URL is blank' do
      before do
        valid_payload[:url] = nil
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :url_blank)).to be_truthy
      end
    end

    context 'when the URL is invalid' do
      before do
        valid_payload[:url] = 'htp:/wws.example.com'
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :invalid_url)).to be_truthy
      end
    end
  end

  describe '#analysis_types_validation' do
    context 'when analysis_types is blank' do
      before do
        valid_payload[:analysis_types] = nil
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :analysis_types_blank)).to be_truthy
      end
    end

    context 'when analysis_types is invalid' do
      before do
        valid_payload[:analysis_types] = 'A not valid analysis type'
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :analysis_types_invalid)).to be_truthy
      end
    end
  end

  describe '#evaluation_or_explanations_presence' do
    context 'when evaluation and explanations are blank' do
      before do
        valid_payload[:analysis_types] = { evaluation: {}, explanations: nil }
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :evaluation_or_explanations)).to be_truthy
      end
    end
  end

  describe '#evaluation_validation' do
    context 'when callback_url is blank' do
      before do
        valid_payload[:analysis_types][:evaluation][:callback_url] = nil
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :evaluation_callback_blank)).to be_truthy
      end
    end

    context 'when callback_url is invalid' do
      before do
        valid_payload[:analysis_types][:evaluation][:callback_url] = 'htp:/wws.example.com'
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :evaluation_callback_invalid)).to be_truthy
      end
    end
  end

  describe '#explanations_validation' do
    context 'when callback_url is blank' do
      before do
        valid_payload[:analysis_types][:explanations][:callback_url] = nil
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :explanations_callback_blank)).to be_truthy
      end
    end

    context 'when callback_url is invalid' do
      before do
        valid_payload[:analysis_types][:explanations][:callback_url] = 'htp:/wws.example.com'
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :explanations_callback_invalid)).to be_truthy
      end
    end

    context 'when explanation_types is blank' do
      before do
        valid_payload[:analysis_types][:explanations][:explanation_types] = nil
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :explanations_explanation_types_blank)).to be_truthy
      end
    end

    context 'when explanation_types is invalid' do
      before do
        valid_payload[:analysis_types][:explanations][:explanation_types] = ['not valid explanations type']
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :explanations_explanation_types_invalid)).to be_truthy
      end
    end
  end

  describe '#content_language_validation' do
    context 'when content_language is not supported' do
      before do
        valid_payload[:content_language] = 'fr'
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :content_language_invalid)).to be_truthy
      end
    end
  end

  describe '#retry_validation' do
    context 'when retry is invalid' do
      before do
        valid_payload[:retry] = 'not valid'
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :retry_invalid)).to be_truthy
      end
    end
  end

  describe '#max_retries_validation' do
    context 'when max_retries is invalid' do
      before do
        valid_payload[:max_retries] = 'not valid'
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :max_retries_invalid)).to be_truthy
      end
    end

    context 'when max_retries is out of range' do
      before do
        valid_payload[:max_retries] = ENV.fetch('API_V1_MAXIMUM_MAX_RETRIES').to_i + 1
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :max_retries_invalid)).to be_truthy
      end
    end
  end

  describe '#timeout_validation' do
    context 'when timeout is invalid' do
      before do
        valid_payload[:timeout] = 'not valid'
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :timeout_invalid)).to be_truthy
      end
    end

    context 'when timeout is out of range' do
      before do
        valid_payload[:timeout] = ENV.fetch('API_V1_MAXIMUM_TIMEOUT').to_i + 1
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :timeout_invalid)).to be_truthy
      end
    end
  end

  describe '#max_chars_validation' do
    context 'when max_chars is invalid' do
      before do
        valid_payload[:max_chars] = 'not valid'
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :max_chars_invalid)).to be_truthy
      end
    end

    context 'when max_chars is out of range' do
      before do
        valid_payload[:max_chars] = ENV.fetch('API_V1_MAXIMUM_MAX_CHARS').to_i + 1
        scrape_payload.valid?
      end

      it 'error is added' do
        expect(scrape_payload.errors.added?(:base, :max_chars_invalid)).to be_truthy
      end
    end
  end
end
