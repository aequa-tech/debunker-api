# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      module Common
        private

        def parse_json(json)
          JSON.parse(json).deep_symbolize_keys
        rescue JSON::ParserError
          json
        end

        def incomplete_status
          206
        end

        def init_support_response_object(incoming_payload_object, token)
          return parse_json(token.support_response_object) if token.support_response_object.present?

          support_object = {}
          support_object[:scrape] = {
            request_id: nil
          }

          support_object[:evaluation] = {
            analysis_id: nil,
            data: {},
            analysis_status: 0,
            callback_status: 0
          }

          support_object[:explanations] = {
            data: [],
            analysis_status: 0,
            callback_status: 0
          }

          support_object
        end

        def success_status?(status)
          return false if status.to_i == incomplete_status

          (status.to_i / 100) == 2
        end

        def set_base_uri_parts
          @base_uri = URI.parse(ENV.fetch('DEBUNKER_API_V1_URL'))
          @base_host = @base_uri.host
          @base_path = @base_uri.path
          @base_port = @base_uri.port
          @base_scheme = @base_uri.scheme
        end

        def post_call(parametrized_path, payload)
          http = Net::HTTP.new(@base_host, @base_port)
          http.use_ssl = @base_scheme == 'https'

          request = Net::HTTP::Post.new(parametrized_path)
          request.basic_auth(ENV.fetch('DEBUNKER_API_USEERNAME'), ENV.fetch('DEBUNKER_API_PASSWORD'))
          request.body = payload.to_json if payload.present?

          http.request(request)
        end

        def get_call(parametrized_path)
          http = Net::HTTP.new(@base_host, @base_port)
          http.use_ssl = @base_scheme == 'https'

          request = Net::HTTP::Get.new(parametrized_path)
          request.basic_auth(ENV.fetch('DEBUNKER_API_USEERNAME'), ENV.fetch('DEBUNKER_API_PASSWORD'))

          http.request(request)
        end
      end
    end
  end
end
