# frozen_string_literal: true

module Api
  module V1
    class DebunkController < AuthenticatedController
      before_action :ensure_available_tokens, only: %i[create]
      before_action :ensure_params, only: %i[create]

      def create
        @token = @user.available_tokens.first
        ::DebunkerAequatech::V1::DebunkerJob.perform_async(@debunk_url, @callback_url, @token.value)
        render json: { message: I18n.t('api.messages.debunk.queued') }, status: :ok
      end

      private

      def debunk_params
        params.permit(:url, :callback_url)
      end

      def ensure_available_tokens
        return if @user.available_tokens.count.positive?

        render json: { error: I18n.t('api.messages.debunk.error.no_tokens') }, status: :forbidden
      end

      def ensure_params
        @debunk_url = debunk_params[:url]
        @callback_url = debunk_params[:callback_url]
        return if @debunk_url.present? && @callback_url.present?

        missings = []
        missings << 'url' unless @debunk_url.present?
        missings << 'callback_url' unless @callback_url.present?

        render json: { error: I18n.t('api.messages.debunk.error.missing_params', params: missings.join(', ')) },
               status: :bad_request
      end
    end
  end
end
