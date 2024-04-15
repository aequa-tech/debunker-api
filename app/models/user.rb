# frozen_string_literal: true

class User < ApplicationRecord
  has_many :tokens, dependent: :destroy
  has_many :api_keys, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  enum role: %i[user admin]

  def info_attributes
    attributes.slice('name', 'email', 'api_key')
  end

  def available_tokens
    tokens.available
  end
end
