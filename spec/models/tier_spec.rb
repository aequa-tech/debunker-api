# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tier, type: :model do
  let(:tier) { create(:tier) } # Assuming you have a Tier factory

  describe 'associations' do
    it { should have_many(:roles).dependent(:nullify) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:tokens_rate) }
    it { should validate_numericality_of(:tokens_rate).is_greater_than(0) }
    it { should validate_presence_of(:reload_rate_amount) }
    it { should validate_numericality_of(:reload_rate_amount).is_greater_than(0) }
    it { should validate_presence_of(:reload_rate_unit) }
    it { should validate_inclusion_of(:reload_rate_unit).in_array(%w[day week month]) }
  end

  describe '#reload_rate_period' do
    it 'returns the reload rate period' do
      tier = Tier.new(reload_rate_amount: 1, reload_rate_unit: 'day')
      expect(tier.reload_rate_period).to eq(1.day)
    end
  end
end
