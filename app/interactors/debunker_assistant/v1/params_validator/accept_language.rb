# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ParamsValidator
      # Validates the locale header for the Debunker Assistant API V1
      class AcceptLanguage
        include Interactor

        def call
          context.fail!(message: I18n.t('api.messages.locale.error.invalid'), status: :bad_request) unless valid_locale?
        end

        private

        def valid_locale?
          locale = context.request.headers['Accept-Language'].to_s
          return true if locale.blank?

          I18n.available_locales.include?(locale.to_sym) && locale.length == 2
        end
      end
    end
  end
end
