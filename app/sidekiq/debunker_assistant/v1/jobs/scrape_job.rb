# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Jobs
      class ScrapeJob
        include Sidekiq::Worker

        def perform(payload, token_value)
          result = ::DebunkerAssistant::V1::ScrapeExecutor::Organizer.call(payload:, token_value:)
          return if result.success?

          requeue(payload, token_value) if result.retry_perform
        end

        private

        def requeue(payload, token_value)
          ::DebunkerAssistant::V1::Jobs::ScrapeJob.perform_in(30.seconds.from_now, payload, token_value)
        end
      end
    end
  end
end
