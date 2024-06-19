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

  describe '.reload_active_keys' do
    let!(:user) { create(:user, :with_api_key) }
    let!(:user2) { create(:user, :with_api_key) }

    before do
      user2.api_keys.each(&:expire!)
      user.api_keys.each { |api_key| api_key.tokens.destroy_all }
    end

    context 'when reload_period is not reached' do
      it 'does not reload active keys' do
        Tier.reload_active_keys
        expect(user.active_api_keys.first.available_tokens).to be_empty
      end

      it 'does not reload expired keys' do
        Tier.reload_active_keys
        expect(user2.api_keys.first.expired?).to be(true)
        expect(user2.api_keys.first.tokens.count).to eq 0
      end
    end

    context 'when reload_period is reached' do
      before do
        user.api_keys.each { |api_key| api_key.update(reloaded_at: (1.month.ago - 1.day)) }
        user2.api_keys.each { |api_key| api_key.update(reloaded_at: (1.month.ago - 1.day)) }
      end

      it 'reloads active keys ' do
        Tier.reload_active_keys
        expect(user.active_api_keys.first.available_tokens.count).to eq(user.role.tier.tokens_rate)
      end

      it 'does not reload expired keys' do
        Tier.reload_active_keys
        expect(user2.api_keys.first.expired?).to be(true)
        expect(user2.api_keys.first.tokens.count).to eq 0
      end
    end
  end
end
