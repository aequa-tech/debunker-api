# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ScrapeQueuer
      # Ensure the token is valid and available and occupy it
      class ReserveToken
        include Interactor

        before :prepare_context

        def call
          return context.token.occupy!(context.parsed_payload) if valid_token?

          context.fail!(message: I18n.t('api.messages.token.error.invalid'), status: :internal_server_error)
        end

        private

        def prepare_context
          context.parsed_payload = ::DebunkerAssistant::V1::Api::ScrapePayload.new(context.payload)
          context.url = context.parsed_payload.url
          context.token = Token.find_by(value: context.token_value)
        end

        def valid_token?
          context.token.present? && context.token.available?
        end
      end
    end
  end
end
