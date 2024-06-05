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

  def response_expetation(data, structure, from = '')
    expectation = true

    if from.empty?
      print "\n[OPENAPI DEFINITION] root "
      extras = cast_array(data&.keys) - cast_array(structure.keys)
      missings = cast_array(structure.keys) - cast_array(data&.keys)

      if extras.any? || missings.any?
        expectation = false
        print '❌'

        print "\nExtras from real data: #{extras}" if extras.any?
        print "\nExtra from definition: #{missings}" if missings.any?
        print "\n"
      else
        print '✅'
      end

      structure.each do |key, value|
        result = response_expetation(data, value, key)
        expectation &&= result
      end
    else
      begin
        compare = from.split(':').map(&:strip).reduce(data) { |memo, key| memo[key] }
      rescue StandardError
        compare = nil
      end

      print "\n[OPENAPI DEFINITION] #{from} "

      if structure.is_a?(Hash)
        extras = cast_array(compare&.keys) - cast_array(structure.keys)
        missings = cast_array(structure.keys) - cast_array(compare&.keys)

        if extras.any? || missings.any?
          expectation = false
          print '❌'

          print "\nExtras from real data: #{extras}" if extras.any?
          print "\nExtra from definition: #{missings}" if missings.any?
          print "\n"

          # return expectation if !expectation && from.split(':').count > 3
        else
          print '✅'
        end

        structure.each do |key, value|
          from = "#{from}:#{key}"

          result = response_expetation(data, value, from)
          expectation &&= result

          from = from.split(':')[0..-2].join(':')
        end
      elsif compare.is_a?(Hash)
        expectation = false
        print '❌'
      else
        print '✅'
      end
    end

    expectation
  end

  def cast_array(data)
    data.is_a?(Array) ? data : data.to_a
  end
end
