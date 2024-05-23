# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ScrapeExecutor
      class Execute
        include Interactor

        before :prepare_context

        def call
          context.token.try! unless context.from_retry == 'incomplete_evaluation'

          if retry_status == :no_retry
            callback rescue nil # rubocop:disable Style/RescueModifier
            context.retry_perform = retry_status
            return context.token.free!
          end

          context.result_perform = perform
          return fail_with_retry! if context.result_perform == :failure

          context.result_callback = callback
          return fail_with_retry! if context.result_callback == :failure
          return fail_with_retry! if context.result_perform == :incomplete_evaluation

          context.token.consume!
        end

        private

        def prepare_context
          context.max_retries = ENV.fetch('TOKEN_MAX_RETRIES').to_i
          context.token = Token.find_by(value: context.token_value) || fail_with_retry!
        end

        def retry_status
          return :retry_incomplete_evaluation if context.result_perform == :incomplete_evaluation
          return :no_retry if context.token.blank?

          context.token.retries < (context.max_retries + 1) ? :retry : :no_retry
        end

        def fail_with_retry!
          context.fail!(retry_perform: retry_status)
        end

        def perform
          ::DebunkerAssistant::V1::Api::ScrapePerform.new(context.payload, context.token.value).scrape
        end

        def callback
          ::DebunkerAssistant::V1::Api::ScrapeCallback.new(context.payload, context.token.value).callback
        end
      end
    end
  end
end
