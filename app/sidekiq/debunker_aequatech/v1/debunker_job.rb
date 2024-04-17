module DebunkerAequatech
  module V1
    class DebunkerJob
      include Sidekiq::Job

      def perform(debunk_url, callback_url, token_value)
        @token = Token.find_by(value: token_value) || return

        init_values(debunk_url, callback_url, token_value)
        last_callback_for_retries and return if @token.retries >= max_retries
        return unless try_perform

        do_callback
      end

      private

      def init_values(debunk_url, callback_url, token_value)
        @debunk_url = CGI.unescape(debunk_url)
        @callback_url = CGI.unescape(callback_url)
        @token_value = token_value
      end

      def last_callback_for_retries
        @payload = @token.last_payload
        @token.free!
        do_callback(last: true)
      rescue Errno::ECONNREFUSED,
             RestClient::Exceptions::ReadTimeout,
             RestClient::ExceptionWithResponse
        nil
      end

      def do_callback(last: false)
        response = RestClient.post(compose_callback_with_params, @payload.to_json, content_type: :json, accept: :json)
        if status_success?(response.code)
          @token.destroy!
        elsif !last
          retry_perform
        end
      rescue Errno::ECONNREFUSED, RestClient::Exceptions::ReadTimeout, RestClient::ExceptionWithResponse
        retry_perform unless last
      end

      def try_perform
        @token.try!
        do_call
        retry_perform unless status_success?(@status)
        status_success?(@status)
      rescue Errno::ECONNREFUSED, RestClient::Exceptions::ReadTimeout, RestClient::ExceptionWithResponse => e
        @payload = { message: e.message }
        @status = e.respond_to?(:http_code) ? e.http_code : 500
        @token.temporary_response!(@payload, @status)
        retry_perform
        false
      end

      def do_call
        @payload, @status = if @token.last_status == 200
                              [@token.last_payload, @token.last_status]
                            else
                              ::DebunkerAequatech::V1::Api.new(CGI.unescape(@debunk_url)).debunk
                            end
        @token.temporary_response!(@payload, @status)
      end

      def retry_perform
        ::DebunkerAequatech::V1::DebunkerJob.perform_in(30.seconds.from_now, @debunk_url, @callback_url, @token_value)
      end

      def compose_callback_with_params
        uri = URI(@callback_url)
        query = [uri.query, "url=#{CGI.escape(@debunk_url)}", "token=#{@token_value}"].select(&:present?).join('&')

        "#{uri.origin}#{uri.path}?#{query}"
      end

      def status_success?(status)
        (status / 100) == 2
      end

      def max_retries
        ENV.fetch('TOKEN_MAX_RETRIES').to_i
      end
    end
  end
end
