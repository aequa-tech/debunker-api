# frozen_string_literal: true

module ApiMethods
  def auth_headers(key_pair)
    { 'X-API-Key' => key_pair[:access_token], 'X-API-Secret' => key_pair[:secret_token] }
  end

  def response_headers_expetations(response, rate_limit: true)
    expect(response.headers['Content-Type']).to eq('application/json; charset=utf-8')
    expect(response.headers['Content-Length']).to eq(response.body.bytesize.to_s)
    return unless rate_limit

    expect(response.headers['X-RateLimit-Limit']).to eq(ENV.fetch('RATE_LIMIT').to_s)
    expect(response.headers['X-RateLimit-Remaining']).not_to be_empty
    expect(response.headers['X-RateLimit-Reset']).not_to be_empty
  end

  def response_message_structure_expetations(json)
    expect(json.keys).to match_array(%w[message])
  end
end
