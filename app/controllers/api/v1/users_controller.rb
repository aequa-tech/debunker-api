# frozen_string_literal: true

module Api
  module V1
    class UsersController < AuthenticatedController
      def status
        render json: {
          user: @user.info_attributes.except('api_key'),
          available_tokens: @user.tokens.count
        }, status: :ok
      end
    end
  end
end
