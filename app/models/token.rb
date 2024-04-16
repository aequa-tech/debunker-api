# frozen_string_literal: true

class Token < ApplicationRecord
  belongs_to :api_key
  validates :value, presence: true, uniqueness: true
  scope :available, -> { where(used_on: nil) }

  def free!
    update_columns(used_on: nil, retries: 0)
  end

  def occupy!(url)
    update_columns(used_on: url, retries: 0)
  end

  def commit!
    update_columns(committed_at: Time.now)
  end
end
