# frozen_string_literal: true

class Token < ApplicationRecord
  belongs_to :api_key
  validates :value, presence: true, uniqueness: true
  scope :available, -> { where(used_on: nil) }

  def free!
    update_columns(used_on: nil, retries: 0, support_response_object: '')
  end

  def occupy!(url)
    update_columns(used_on: url, retries: 0)
  end

  def temporary_response!(payload, status)
    payload = payload.to_json if payload.is_a?(Hash)
    status = status.to_i if status.is_a?(String)
    update_columns(support_response_object: payload, success: status)
  end

  def try!
    update_columns(retries: retries + 1)
  end

  def consume!
    token.destroy!
  end
end
