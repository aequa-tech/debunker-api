# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ParamsValidator
      # Checks if the api_key has the necessary tokens
      class AvailableTokens
        include Interactor

        before :prepare_context

        def call
          return if api_key.available_tokens.count.positive?

          context.fail!(message: I18n.t('api.messages.scrape.error.no_tokens', status: :forbidden))
        end

        private

        def prepare_context
          context.key = context.request.headers['X-API-Key']
        end

        def api_key
          ApiKey.find_by(access_token: context.key)
        end
      end
    end
  end
end
