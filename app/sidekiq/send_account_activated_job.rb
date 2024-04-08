# frozen_string_literal: true

class SendAccountActivatedJob
  include Sidekiq::Job

  queue_as :mailers

  def perform(user_id)
    user = User.find(user_id)
    UserMailer.account_activated(user).deliver_now
  end
end
