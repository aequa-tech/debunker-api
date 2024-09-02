# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      class ScrapeController < RequestController
        before_action :set_token_value

        def create
          result = ::DebunkerAssistant::V1::ScrapeQueuer::Organizer.call(
            payload: request.body.read,
            token_value: @token_value
          )
          return render json: { message: result.message }, status: result.status unless result.success?

          render json: { token_id: @token_value, message: I18n.t('api.messages.scrape.queued'), url: result.url },
                 status: :ok
        end

        private

        def set_token_value
          @token_value = ApiKey.find_by(access_token: request.headers['X-API-Key']).available_tokens.first.value
        end
      end
    end
  end
end
