# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      # API for debunking URLs and performing analysis
      # Expect a valid payload
      class ScrapePerform
        include Common

        attr_reader :payload

        def initialize(payload, token_value)
          @base_url = ENV.fetch('DEBUNKER_API_V1_URL')

          @incoming_payload = ::DebunkerAssistant::V1::Api::ScrapePayload.new(payload)
          @token = Token.find_by(value: token_value)
          @support_response_object = init_support_response_object(@incoming_payload, @token)
        end

        def scrape
          @request_id = llm_scrape
          @token.temporary_response!(@support_response_object.to_json) and return perform_outcome unless @request_id

          @incoming_payload.analysis_types.each_key do |analysis_type|
            perform_analysis(analysis_type)
          end

          @token.temporary_response!(@support_response_object.to_json)
          perform_outcome
        end

        private

        def llm_scrape
          response = RestClient.post([@base_url, 'scrape'].join('/') + "?url=#{@incoming_payload.url}", {})
          payload = parse_json(response.body)
          return payload[:result][:request_id] if status_success?(payload[:status])

          scrape_fail_all(payload[:message], payload[:status])
        rescue RestClient::ExceptionWithResponse,
               RestClient::Exceptions::ReadTimeout,
               JSON::ParserError => e
          scrape_fail_all(e.message, e.try(:http_code) || 500)
        end

        def perform_analysis(analysis_type)
          @current_analysis_type = analysis_type
          return if must_skip_analysis?

          response = RestClient.get([@base_url, 'danger', request_id].join('/'))
          payload = parse_json(response.body)
          scrape_success(analysis_type, payload[:result], payload[:status])
        rescue RestClient::ExceptionWithResponse,
               RestClient::Exceptions::ReadTimeout,
               JSON::ParserError => e
          scrape_fail(@current_analysis_type, e.message, e.try(:http_code) || 500)
        end

        def must_skip_analysis?
          success_status?(@support_response_object[analysis_type][:callback_status]) ||
            success_status?(@support_response_object[analysis_type][:analysis_status])
        end

        def scrape_success(analysis_type, data, status)
          @support_response_object[analysis_type] = { data:, analysis_status: status, callback_status: 0 }
        end

        def scrape_fail(analysis_type, message, status)
          @support_response_object[analysis_type] = { data: { message: }, analysis_status: status, callback_status: 0 }
        end

        def scrape_fail_all(message, status)
          @incoming_payload.analysis_types.each_key do |analysis_type|
            scrape_fail(analysis_type, message, status)
          end
        end

        def perform_outcome
          @incoming_payload.analysis_types.keys.map do |analysis_type|
            success_status?(@support_response_object[analysis_type][:analysis_status])
          end.all?
        end
      end
    end
  end
end
