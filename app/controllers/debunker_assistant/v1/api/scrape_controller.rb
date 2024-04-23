# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      class ScrapeController < RequestController
        before_action :prepare_payload_and_token

        def create
          token_value = ApiKey.find_by(key: request.headers['X-API-Key']).available_tokens.first.value
          result = ::DebunkerAssistant::V1::ScrapeQueuer::Organizer.call(payload: request.body.read, token_value:)
          return render json: { message: result.message }, status: result.status if result.failure?

          render json: { message: result.message, url: result.url, token: result.token.value }, status: :ok
        end
      end
    end
  end
end
