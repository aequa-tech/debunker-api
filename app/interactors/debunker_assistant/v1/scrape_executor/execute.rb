# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ScrapeExecutor
      class Execute
        include Interactor

        before :prepare_context

        def call
          context.token.try!

          unless retry?
            callback rescue nil # rubocop:disable Style/RescueModifier
            return context.token.free!
          end

          return fail_with_retry! unless perform
          return fail_with_retry! unless callback

          context.token.consume!
        end

        private

        def prepare_context
          context.max_retries = ENV.fetch('TOKEN_MAX_RETRIES').to_i
          context.token = Token.find_by(value: context.token_value) || fail_with_retry!
        end

        def retry?
          context.token.retries < (context.max_retries + 1)
        end

        def fail_with_retry!
          context.fail!(retry_perform: retry?)
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
