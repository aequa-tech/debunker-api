# frozen_string_literal: true

class Token < ApplicationRecord
  belongs_to :user

  validates :value, presence: true, uniqueness: true
end
