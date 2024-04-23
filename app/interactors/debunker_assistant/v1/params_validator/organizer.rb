# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ParamsValidator
      # Organizes the params validation interactors for
      # the Debunker Assistant API V1
      class Organizer
        include ::Interactor::Organizer

        organize AcceptLanguage, ValidParams
      end
    end
  end
end
