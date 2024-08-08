# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      # Controller responsible for handling authenticated API requests in the V1 namespace.
      class AuthenticatedController < ApplicationController
        before_action :validate_locale
        before_action :set_locale
        before_action :authenticate!

        private

        def validate_locale
          result = DebunkerAssistant::V1::ParamsValidator::AcceptLanguage.call(request:)
          return if result.success?

          render json: { message: result.message }, status: result.status
        end

        def set_locale
          accept_language = request.headers['Accept-Language'].to_s
          I18n.locale = accept_language if accept_language.present?
        end

        def authenticate!
          result = DebunkerAssistant::V1::ApiAuthenticator::Organizer.call(request:)
          if result.success?
            Current.user = result.current_user
            return
          end

          render json: { message: result.message }, status: result.status
        end
      end
    end
  end
end
