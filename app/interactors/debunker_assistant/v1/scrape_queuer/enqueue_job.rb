# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ScrapeQueuer
      # Enqueue a job to scrape a URL
      class EnqueueJob
        include Interactor

        before :prepare_context

        def call
          ::DebunkerAssistant::V1::Jobs::ScrapeJob.perform_async(context.token.value)
        rescue StandardError
          context.fail!(message: I18n.t('api.messages.errors.fatal'), status: :internal_server_error)
        end

        private

        def prepare_context
          context.token = Token.find_by(value: context.token_value)
          return if context.token.present?

          context.fail!(message: I18n.t('api.messages.errors.fatal'), status: :internal_server_error)
        end
      end
    end
  end
end
