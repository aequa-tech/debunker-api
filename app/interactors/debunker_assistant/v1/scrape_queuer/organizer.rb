# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module ScrapeQueuer
      # Organize the process of scraping a URL
      class Organizer
        include Interactor::Organizer

        organize ReserveToken, EnqueueJob
      end
    end
  end
end
