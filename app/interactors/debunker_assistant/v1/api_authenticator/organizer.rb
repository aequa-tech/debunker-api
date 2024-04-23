# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ApiAuthenticator
      # Organizes the API authenticator interactors for
      # the Debunker Assistant API V1
      class Organizer
        include ::Interactor::Organizer

        organize KeyPresence, SecretPresence, Authenticate
      end
    end
  end
end
