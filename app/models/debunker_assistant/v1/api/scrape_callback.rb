# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      class ScrapeCallback
        include Common

        def initialize(payload, token_value)
          @token = Token.find_by(value: token_value)
          @incoming_payload = ::DebunkerAssistant::V1::Api::ScrapePayload.new(payload)
          @support_response_object = init_support_response_object(@incoming_payload, @token)
        end

        def callback
          @incoming_payload.analysis_types.each_key do |type|
            perform_callback(type)
          end

          @token.temporary_response!(@support_response_object.to_json)
          callback_outcome
        end

        private

        def perform_callback(type)
          return if success_status?(@support_response_object[type][:callback_status])

          response = RestClient.post(@incoming_payload.analysis_types[:callback_url],
                                     response_payload.to_json, content_type: :json, accept: :json)
          @support_response_object[type][:callback_status] = response.code
        rescue RestClient::ExceptionWithResponse,
               RestClient::Exceptions::ReadTimeout,
               JSON::ParserError => e
          @support_response_object[type][:callback_status] = e.try(:http_code) || 500
        end

        def callback_outcome
          @incoming_payload.analysis_types.keys.map do |analysis_type|
            success_status?(@support_response_object[analysis_type][:callback_status])
          end.all?
        end

        def response_payload
          { url: @incoming_payload.url, token: @token.value, data: @support_response_object }
        end
      end
    end
  end
end