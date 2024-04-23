# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ApiAuthenticator
      # Checks if the API key is present in the request
      class SecretPresence
        include ::Interactor

        before :prepare_context

        def call
          return if context.secret.present?

          context.fail!(message: I18n.t('api.messages.api_key.error.missings'), status: :unauthorized)
        end

        private

        def prepare_context
          context.secret = context.request.headers['X-API-Secret']
        end
      end
    end
  end
end
