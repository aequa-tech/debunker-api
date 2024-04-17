# frozen_string_literal: true

module Api
  module V1
    class DebunkController < AuthenticatedController
      before_action :ensure_params, only: %i[create]
      before_action :ensure_protocol, only: %i[create]
      before_action :ensure_available_tokens, only: %i[create]

      def create
        @token = @api_key.available_tokens.first
        @token.occupy!(@debunk_url)

        ::DebunkerAequatech::V1::DebunkerJob.perform_async(@debunk_url, @callback_url, @token.value)
        render json: {
          message: I18n.t('api.messages.debunk.queued'), url: @debunk_url, token: @token.value
        }, status: :ok
      end

      private

      def debunk_params
        params.permit(:url, :callback_url)
      end

      def ensure_available_tokens
        return if @api_key.available_tokens.count.positive?

        render json: { message: I18n.t('api.messages.debunk.error.no_tokens'),
                       url: @debunk_url, token: '' }, status: :forbidden
      end

      def ensure_params
        @debunk_url = CGI.unescape(debunk_params[:url])
        @callback_url = CGI.unescape(debunk_params[:callback_url])
        return if @debunk_url.present? && @callback_url.present?

        missings = []
        missings << 'url' unless @debunk_url.present?
        missings << 'callback_url' unless @callback_url.present?

        render json: { message: I18n.t('api.messages.debunk.error.missing_params', params: missings.join(', ')),
                       url: @debunk_url, token: '' }, status: :bad_request
      end

      def ensure_protocol
        return if @debunk_url.start_with?('http://') || @debunk_url.start_with?('https://')

        render json: { message: I18n.t('api.messages.debunk.error.protocol'), url: @debunk_url, token: '' },
               status: :bad_request
      end
    end
  end
end
