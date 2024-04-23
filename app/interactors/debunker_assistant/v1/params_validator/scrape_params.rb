# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ParamsValidator
      # Validates the params for the scrape route Debunker Assistant API V1
      class ScrapeParams
        include Interactor

        def call
          scrape_payload = ::DebunkerAssistant::V1::Api::ScrapePayload.new(context.request.body.read)
          return if scrape_payload.valid?

          context.fail!(message: scrape_payload.errors.full_messages.join(', '), status: :bad_request)
        end
      end
    end
  end
end
