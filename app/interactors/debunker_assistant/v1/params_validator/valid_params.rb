# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ParamsValidator
      # Validates the common params for the Debunker Assistant API V1
      class ValidParams
        include ::Interactor

        def call
          if status_route?
            result = DebunkerAssistant::V1::ParamsValidator::UsersStatusParams.call(context)
            context.fail!(message: result.message) unless result.success?

          elsif scrape_route?
            result_params = DebunkerAssistant::V1::ParamsValidator::ScrapeParams.call(context)
            context.fail!(message: result_params.message) unless result_params.success?

            result = ::DebunkerAssistant::::V1::ApiAuthenticator::Organizer.call(context)
            context.fail!(message: result.message, status: result.status) unless result.success?

            result_token = DebunkerAssistant::V1::ParamsValidator::AvailableTokens.call(context)
            context.fail!(message: result_token.message) unless result_token.success?
          end
        end

        def status_route?
          context.request.path.ends_with?('/users/status')
        end

        def scrape_route?
          context.request.path.ends_with?('/scrape')
        end
      end
    end
  end
end
