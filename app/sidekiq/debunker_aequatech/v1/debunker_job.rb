module DebunkerAequatech
  module V1
    class DebunkerJob
      include Sidekiq::Job

      def perform(debunk_url, callback_url, token_value)
        token = Token.find_by(value: token_value)
        return unless token
        return if token.retries >= ENV.fetch('TOKEN_MAX_RETRIES').to_i

        token.update!(retries: token.retries + 1)
        debuker_api = DebunkerAequatech::V1::Api.new(debunk_url)
        payload, status = debuker_api.debunk
        return unless status == 200

        response = RestClient.post(callback_url, payload.to_json, content_type: :json, accept: :json)
        Token.find_by(value: token).update!(committed_at: Time.zone.now) if response.code == 200
      end
    end
  end
end
