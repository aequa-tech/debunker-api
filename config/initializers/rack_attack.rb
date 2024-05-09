# frozen_string_literal: true

# With this configuration, we are going to throttle the requests to 5 requests per minute.
# The throttle is going to be applied to the API key or the IP address if the API key is not present.
Rack::Attack.throttle('ratelimiting',
                      limit: ENV.fetch('RATE_LIMIT').to_i,
                      period: ENV.fetch('RATE_LIMIT_PERIOD_MINUTES').to_i.minutes) do |request|
  request.env['HTTP_X_API_KEY'] || 'no-key'
end

# This is the response that will be sent when the throttle is reached.
# The response is going to be a 429 status code with a JSON message.
# Headers will be modified in DebunkerAssistant::V1::Middleware::ResponseHeaders
# adding Rate limiting information and content length
Rack::Attack.throttled_responder = lambda do |_env|
  [
    429,
    { 'Content-Type' => 'application/json; charset=utf-8' },
    [{ message: I18n.t('api.messages.api_key.error.too_many_requests') }.to_json]
  ]
end
