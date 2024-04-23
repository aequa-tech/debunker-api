# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      module Common
        private

        def parse_json(json)
          JSON.parse(json).deep_symbolize_keys
        rescue JSON::ParserError
          {}
        end

        def init_support_response_object(incoming_payload_object, token)
          return parse_json(token.support_response_object) if token.support_response_object.present?

          support_object = {}
          incoming_payload_object.analysis_types.each_key do |analysis_type|
            support_object[analysis_type] = {
              data: {},
              analysis_status: 0,
              callback_status: 0
            }
          end
          support_object
        end

        def success_status?(status)
          (status.to_i / 100) == 2
        end
      end
    end
  end
end
