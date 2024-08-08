# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ApiAuthenticator
      # Authenticates the API request
      class Authenticate
        include ::Interactor

        def call
          if (user = ApiKey.authenticate!(context.key, context.secret))
            context.current_user = user
            return
          end

          context.fail!(message: I18n.t('api.messages.api_key.error.unauthorized'), status: :unauthorized)
        end
      end
    end
  end
end
