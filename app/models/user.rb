# frozen_string_literal: true

class User < ApplicationRecord
  has_many :tokens, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  def info_attributes
    attributes.slice('name', 'email', 'api_key')
  end
end
