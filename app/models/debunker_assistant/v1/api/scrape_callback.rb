# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      class ScrapeCallback
        include Common

        def initialize(token_value)
          @token = Token.find_by(value: token_value)
          return unless @token

          @incoming_payload = ::DebunkerAssistant::V1::Api::ScrapePayload.new(@token.payload_json)
          @response_object = @token.response_object
        end

        def callback
          @incoming_payload.analysis_types.each_key do |type|
            perform_callback(type)
          end

          @token.persist!(@response_object, kind: :response)
          callback_outcome
        end

        def check_callback_payload(type)
          raise NotImplementedError unless Rails.env.test?

          response_payload(type)
        end

        private

        def perform_callback(type)
          return if success_status?(@response_object[type][:callback_status])

          response = RestClient.post(@incoming_payload.analysis_types[type][:callback_url],
                                     response_payload(type).to_json, content_type: :json, accept: :json)
          @response_object[type][:callback_status] = response.code
        rescue Errno::ECONNREFUSED,
               Net::ReadTimeout,
               RestClient::ExceptionWithResponse,
               RestClient::Exceptions::ReadTimeout,
               JSON::ParserError => e
          @response_object[type][:callback_status] = e.try(:http_code) || 500
        end

        def callback_outcome
          @token.callback_outcome
        end

        def response_payload(type)
          {
            token_id: @token.value,
            url: @incoming_payload.url,
            analysisType: type.to_s,
            data: @response_object[type][:data]
          }
        end
      end
    end
  end
end
