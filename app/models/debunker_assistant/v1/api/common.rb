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
      end
    end
  end
end
