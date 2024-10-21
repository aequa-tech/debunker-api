# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Jobs
      class ScrapeJob
        include Sidekiq::Worker

        def perform(token_value, from_retry = nil)
          result = ::DebunkerAssistant::V1::ScrapeExecutor::Organizer.call(token_value:, from_retry:)
          return if result.retry_perform == :no_retry

          from_now_requeue, from_retry_requeue = retry_info(result)
          requeue(token_value, from_now_requeue, from_retry_requeue)
        end

        private

        def requeue(token_value, from_now, from_retry)
          ::DebunkerAssistant::V1::Jobs::ScrapeJob.perform_in(from_now, token_value, from_retry)
        end

        def retry_info(result)
          return [24.hours.from_now, 'incomplete_evaluation'] if result.retry_perform == :retry_incomplete_evaluation

          [30.seconds.from_now, nil]
        end
      end
    end
  end
end
