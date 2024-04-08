class DebunkerJob
  include Sidekiq::Job

  def perform(debunk_url, callback_url, token)

  end
end
