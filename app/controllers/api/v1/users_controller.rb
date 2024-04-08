# frozen_string_literal: true

module Api
  module V1
    class UsersController < AuthenticatedController
      def status
        render json: {
          user: @user.info_attributes.except('api_key'),
          tokens: {
            count: @user.tokens.count,
            list: @user.tokens.map(&:value)
          }
        }, status: :ok
      end
    end
  end
end
