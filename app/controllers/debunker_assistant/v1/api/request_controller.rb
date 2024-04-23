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
      end
    end
  end
end
