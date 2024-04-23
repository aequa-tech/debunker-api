# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ParamsValidator
      # Validates the params for the users/status route Debunker Assistant API V1
      class UsersStatusParams
        include Interactor

        # For now, we are not validating anything for this route
        def call
          true
        end
      end
    end
  end
end
