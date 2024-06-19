# frozen_string_literal: true

class Role < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  enum role_type: %i[user admin]

  has_many :users, dependent: :nullify
  belongs_to :tier

  after_initialize :set_default_role_type, if: :new_record?

  private

  def set_default_role_type
    self.role_type ||= :user
  end
end
