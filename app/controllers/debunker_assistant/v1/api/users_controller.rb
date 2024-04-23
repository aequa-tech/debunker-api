# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Api
      # Controller responsible for handling user status API requests in the V1 namespace.
      class UsersController < RequestController
        def status
          render json: {
            user: @user.info_attributes.except('api_key'),
            available_tokens: @api_key.available_tokens.count
          }, status: :ok
        end
      end
    end
  end
end
