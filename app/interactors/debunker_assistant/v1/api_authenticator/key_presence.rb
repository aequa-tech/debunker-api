# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ApiAuthenticator
      # Checks if the API key is present in the request
      class KeyPresence
        include ::Interactor

        before :prepare_context

        def call
          return if context.key.present?

          context.fail!(message: I18n.t('api.messages.api_key.error.missings'), status: :unauthorized)
        end

        private

        def prepare_context
          context.key = context.request.headers['X-API-Key']
        end
      end
    end
  end
end
