# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ScrapeExecutor
      class ValidPayload
        include Interactor

        def call
          scrape_payload = ::DebunkerAssistant::V1::Api::ScrapePayload.new(context.payload)
          return if scrape_payload.valid?

          context.fail!(retry_perform: :no_retry)
        end
      end
    end
  end
end
