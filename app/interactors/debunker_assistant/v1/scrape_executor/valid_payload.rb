# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ScrapeExecutor
      class ValidPayload
        include Interactor

        before :prepare_context

        def call
          scrape_payload = ::DebunkerAssistant::V1::Api::ScrapePayload.new(context.token.payload_json)
          return if scrape_payload.valid?

          fail_and_no_retry!
        end

        private

        def prepare_context
          context.token = Token.find_by(value: context.token_value) || fail_and_no_retry!
        end

        def fail_and_no_retry!
          if context.token.present?
            context.token.status!(:invalid, kind: :perform)
            context.token.status!(:invalid, kind: :callback)
          end

          context.fail!(retry_perform: :no_retry)
        end
      end
    end
  end
end
