# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      # Validates the common params for the Debunker Assistant API V1
      class RequestController < AuthenticatedController
        before_action :validate_params

        private

        def validate_params
          result = DebunkerAssistant::V1::ParamsValidator::Organizer.call(request:)
          return if result.success?

          render json: { message: result.message }, status: result.status
        end

        def api_key
          @api_key ||= ApiKey.find_by(access_token: request.headers['X-API-Key'])
        end

        def ensure_admin
          return if api_key.user.admin?

          render json: { message: I18n.t('api.messages.api_key.error.unauthorized') }, status: :unauthorized
        end
      end
    end
  end
end
