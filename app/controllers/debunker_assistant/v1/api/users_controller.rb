# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      # Controller responsible for handling user status API requests in the V1 namespace.
      class UsersController < RequestController
        def status
          render json: {
            user: api_key.user.info_attributes,
            available_tokens: api_key.available_tokens.count
          }, status: :ok
        end

        private

        def api_key
          @api_key ||= ApiKey.find_by(access_token: request.headers['X-API-Key'])
        end
      end
    end
  end
end
