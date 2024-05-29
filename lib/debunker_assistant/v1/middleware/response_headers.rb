# frozen_string_literal: true

module DebunkerAssistant
  module V1
    module Middleware
      # This class is a middleware that adds the Content-Length and RateLimit headers to the response.
      # It also removes all headers except Content-Type.
      # The RateLimit headers are calculated using the Rack::Attack throttle_data.
      # The throttle_data is set by the Rack::Attack middleware also for 429 error response message.
      # The middleware is only applied to the v1 API.
      class ResponseHeaders
        def initialize(app)
          @app = app
        end

        def call(env)
          status, headers, response = @app.call(env)
          return [status, headers, response] unless v1?(env)

          response_body = body_response(response)
          new_headers = response_headers(headers, response_body, env, add_rate_limit: scrape_path?(env))

          [status, new_headers, [response_body]]
        end

        private

        def v1?(env)
          env['PATH_INFO'].start_with?('/api/v1/')
        end

        def scrape_path?(env)
          env['PATH_INFO'].include?('/scrape')
        end

        def body_response(response)
          response.body
        rescue ::NoMethodError
          response[0]
        end

        def rate_limit_headers(env)
          match_data = env['rack.attack.throttle_data']['ratelimiting']
          now = match_data[:epoch_time]

          remaining = match_data[:limit].to_i - match_data[:count].to_i
          remaining = 0 if remaining.negative?

          [match_data[:limit].to_i, remaining, (now + (match_data[:period] - now % match_data[:period]))]
        end

        def response_headers(old_headers, response_body, env, add_rate_limit: true)
          # Remove all headers except Content-Type
          old_headers = old_headers.select { |key, _| key == 'Content-Type' }

          # Set Content-Length and RateLimit headers
          old_headers['Content-Length'] = response_body.bytesize.to_s
          if add_rate_limit
            rate_limit, rate_remaining, rate_reset = rate_limit_headers(env)
            old_headers['X-RateLimit-Limit'] = rate_limit.to_s
            old_headers['X-RateLimit-Remaining'] = rate_remaining.to_s
            old_headers['X-RateLimit-Reset'] = rate_reset.to_s
          end
          old_headers
        end
      end
    end
  end
end
