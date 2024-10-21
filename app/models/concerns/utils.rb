# frozen_string_literal: true

module Utils
  include ActiveSupport::Concern

  private

  def parse_json(json)
    JSON.parse(json).deep_symbolize_keys
  rescue JSON::ParserError
    json
  end

  def incomplete_status
    206
  end

  def success_status?(status)
    return false if status.to_i == incomplete_status

    (status.to_i / 100) == 2
  end
end
