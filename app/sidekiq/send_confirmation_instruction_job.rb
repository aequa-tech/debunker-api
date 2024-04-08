# frozen_string_literal: true

class SendConfirmationInstructionJob
  include Sidekiq::Job

  queue_as :mailers

  def perform(user_id)
    user = User.find(user_id)
    UserMailer.confirmation_instructions(user).deliver_now
  end
end
