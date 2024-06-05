# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

RSpec.configure do |config|
  config.before(:suite) do
    payload = {
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

    @base_uri = URI.parse(ENV.fetch('DEBUNKER_API_V1_URL'))
    @base_host = @base_uri.host
    @base_path = @base_uri.path
    @base_port = @base_uri.port
    @base_scheme = @base_uri.scheme

    VCR.use_cassette('scrape_success') do
      http = Net::HTTP.new(@base_host, @base_port)
      http.use_ssl = @base_scheme == 'https'

      request = Net::HTTP::Post.new('/internal/v1/scrape?inputUrl=https://www.google.com&language=en&maxChars=1000&maxRetries=3&retry=true&timeout=10')
      http.request(request)
    end

    failure = YAML.load_file(Rails.root.join('spec', 'fixtures', 'vcr_cassettes', 'scrape_success.yml')).deep_symbolize_keys
    failure[:http_interactions].first[:response][:status][:code] = 500
    failure[:http_interactions].first[:response][:status][:message] = 'Internal Server Error'
    failure[:http_interactions].first[:response][:body][:string] = 'Internal Server Error'
    failure[:http_interactions].first[:response][:headers]['Content-Type'] = 'text/plain; charset=utf-8'
    failure[:http_interactions].first[:response][:headers]['Content-Length'] = 'Internal Server Error'.length.to_s
    File.open(Rails.root.join('spec', 'fixtures', 'vcr_cassettes', 'scrape_failure.yml'), 'w') { |file| file.write(failure.deep_stringify_keys.to_yaml) }

    VCR.use_cassette('evaluation_success') do
      http = Net::HTTP.new(@base_host, @base_port)
      http.use_ssl = @base_scheme == 'https'

      request = Net::HTTP::Get.new('/internal/v1/evaluation?request_id=8ffdefbdec956b595d257f0aaeefd623')
      http.request(request)
    end

    failure = YAML.load_file(Rails.root.join('spec', 'fixtures', 'vcr_cassettes', 'evaluation_success.yml')).deep_symbolize_keys
    failure[:http_interactions].first[:response][:status][:code] = 200
    failure[:http_interactions].first[:response][:status][:message] = 'OK'
    failure[:http_interactions].first[:response][:body][:string] = '{"status":404}'
    failure[:http_interactions].first[:response][:headers]['Content-Type'] = 'text/plain; charset=utf-8'
    failure[:http_interactions].first[:response][:headers]['Content-Length'] = '{"status":404}'.length.to_s
    File.open(Rails.root.join('spec', 'fixtures', 'vcr_cassettes', 'evaluation_failure.yml'), 'w') { |file| file.write(failure.deep_stringify_keys.to_yaml) }

    VCR.use_cassette('explanation_affective_success') do
      http = Net::HTTP.new(@base_host, @base_port)
      http.use_ssl = @base_scheme == 'https'

      request = Net::HTTP::Get.new('/internal/v1/explanations?analysis_id=8ffdefbdec956b595d257f0aaeefd623&explanation_type=explanationAffective')
      http.request(request)
    end

    failure = YAML.load_file(Rails.root.join('spec', 'fixtures', 'vcr_cassettes', 'explanation_affective_success.yml')).deep_symbolize_keys
    failure[:http_interactions].first[:response][:status][:code] = 500
    failure[:http_interactions].first[:response][:status][:message] = 'Internal Server Error'
    failure[:http_interactions].first[:response][:body][:string] = 'Internal Server Error'
    failure[:http_interactions].first[:response][:headers]['Content-Type'] = 'text/plain; charset=utf-8'
    failure[:http_interactions].first[:response][:headers]['Content-Length'] = 'Internal Server Error'.length.to_s
    File.open(Rails.root.join('spec', 'fixtures', 'vcr_cassettes', 'explanation_affective_failure.yml'), 'w') { |file| file.write(failure.deep_stringify_keys.to_yaml) }

    VCR.use_cassette('explanation_danger_success') do
      http = Net::HTTP.new(@base_host, @base_port)
      http.use_ssl = @base_scheme == 'https'

      request = Net::HTTP::Get.new('/internal/v1/explanations?analysis_id=8ffdefbdec956b595d257f0aaeefd623&explanation_type=explanationDanger')
      http.request(request)
    end

    failure = YAML.load_file(Rails.root.join('spec', 'fixtures', 'vcr_cassettes', 'explanation_danger_success.yml')).deep_symbolize_keys
    failure[:http_interactions].first[:response][:status][:code] = 500
    failure[:http_interactions].first[:response][:status][:message] = 'Internal Server Error'
    failure[:http_interactions].first[:response][:body][:string] = 'Internal Server Error'
    failure[:http_interactions].first[:response][:headers]['Content-Type'] = 'text/plain; charset=utf-8'
    failure[:http_interactions].first[:response][:headers]['Content-Length'] = 'Internal Server Error'.length.to_s
    File.open(Rails.root.join('spec', 'fixtures', 'vcr_cassettes', 'explanation_danger_failure.yml'), 'w') { |file| file.write(failure.deep_stringify_keys.to_yaml) }

    VCR.use_cassette('explanation_network_success') do
      http = Net::HTTP.new(@base_host, @base_port)
      http.use_ssl = @base_scheme == 'https'

      request = Net::HTTP::Get.new('/internal/v1/explanations?analysis_id=8ffdefbdec956b595d257f0aaeefd623&explanation_type=explanationNetworkAnalysis')
      http.request(request)
    end
  end
end
