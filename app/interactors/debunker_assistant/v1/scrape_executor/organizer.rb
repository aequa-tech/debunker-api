# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ScrapeExecutor
      class Organizer
        include Interactor::Organizer

        organize ValidPayload, Execute
      end
    end
  end
end
