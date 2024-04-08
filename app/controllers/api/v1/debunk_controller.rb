# frozen_string_literal: true

module Api
  module V1
    class DebunkController < AuthenticatedController
      before_action :ensure_available_tokens, only: %i[create]
      before_action :ensure_params, only: %i[create]

      def create
        @token = @user.tokens.first
        DebunkerJob.perform_async(@debunk_url, @callback_url, @token.value)
      end

      private

      def debunk_params
        params.permit(:url, :callback_url)
      end

      def ensure_available_tokens
        return if @user.tokens.count.positive?

        render json: { error: I18n.t('api.messages.debunk.error.no_tokens') }, status: :forbidden
      end

      def ensure_params
        @debunk_url = debunk_params[:url]
        @callback_url = debunk_params[:callback_url]
        return if @debunk_url.present?

        render json: { error: I18n.t('api.messages.debunk.error.missing_params_url') },
               status: :unprocessable_entity
      end
    end
  end
end
