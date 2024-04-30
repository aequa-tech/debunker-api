# frozen_string_literal: true

class Token < ApplicationRecord
  belongs_to :api_key
  validates :value, presence: true, uniqueness: true
  scope :available, -> { where(used_on: nil) }

  def available?
    used_on.nil?
  end

  def free!
    update_columns(used_on: nil, retries: 0, support_response_object: '')
  end

  def occupy!(url)
    update_columns(used_on: url, retries: 0, support_response_object: '')
  end

  def temporary_response!(payload)
    payload = payload.to_json if payload.is_a?(Hash)
    update_columns(support_response_object: payload)
  end

  def try!
    update_columns(retries: retries + 1)
  end

  def consume!
    destroy!
  end
end
