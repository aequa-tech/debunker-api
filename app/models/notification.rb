# frozen_string_literal: true

class Notification
  class << self
    def request(token:, type:)
      case type
      when :started then request_started(token:)
      when :updated then request_updated(token:)
      when :finished then request_finished(token:)
      end
    end

    private

    def request_started(token:)
      ActiveSupport::Notifications.instrument('started.token', this: token.to_json)
    end

    def request_updated(token:)
      ActiveSupport::Notifications.instrument('updated.token', this: token.to_json)
    end

    def request_finished(token:)
      ActiveSupport::Notifications.instrument('finished.token', this: token.to_json)
    end
  end
end
