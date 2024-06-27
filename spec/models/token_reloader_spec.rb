require 'rails_helper'

RSpec.describe TokenReloader, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:tier) }
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:api_key) }
  end

  describe '#initialize' do
    let(:api_key) { create(:api_key) }

    context 'when api_key is not present' do
      it 'does not initialize the object' do
        token_reloader = described_class.new
        expect(token_reloader.api_key).to be_nil
        expect(token_reloader.user).to be_nil
        expect(token_reloader.tier).to be_nil
        expect(token_reloader.reload_rate_period).to be_nil
        expect(token_reloader.tokens_rate).to be_nil
        expect(token_reloader.next_reload_date).to be_nil
      end
    end

    context 'when api_key is present' do
      let(:api_key) { create(:api_key) }

      it 'initializes the object' do
        token_reloader = described_class.new(api_key)
        expect(token_reloader.api_key).to eq(api_key)
        expect(token_reloader.user).to eq(api_key.user)
        expect(token_reloader.tier).to eq(api_key.user.role.tier)
        expect(token_reloader.reload_rate_period).to eq(api_key.user.role.tier.reload_rate_period)
        expect(token_reloader.tokens_rate).to eq(api_key.user.role.tier.tokens_rate)
        expect(token_reloader.next_reload_date).to eq(api_key.reloaded_at + token_reloader.reload_rate_period)
      end

      context 'when force_tokens_rate is present' do
        it 'initializes the object with the forced tokens rate' do
          token_reloader = described_class.new(api_key, force_tokens_rate: 10)
          expect(token_reloader.tokens_rate).to eq(10)
        end
      end
    end
  end

  describe '#reload_tokens' do
    let(:api_key) { create(:api_key) }
    let(:token_reloader) { described_class.new(api_key) }

    context 'when api_key is not active' do
      before do
        allow(api_key).to receive(:expired?).and_return(true)
        api_key.tokens.destroy_all
      end

      it 'does not reload tokens' do
        token_reloader.reload_tokens
        api_key.reload
        expect(api_key.tokens.count).to eq 0
      end
    end

    context 'when next_reload_date is not past' do
      let(:api_key) { create(:api_key, reloaded_at: Date.tomorrow) }

      before do
        api_key.tokens.destroy_all
        token_reloader.reload_tokens
        api_key.reload
      end

      it 'does not reload tokens' do
        expect(api_key.tokens.count).to eq 0
      end
    end

    context 'when next_reload_date is past' do
      let!(:api_key) { create(:api_key) }

      before do
        api_key.tokens.destroy_all
        api_key.update(reloaded_at: 1.month.ago - 1.day)
        token_reloader.reload_tokens
        api_key.reload
      end

      it 'reloads tokens' do
        expect(api_key.tokens.count).to eq api_key.user.role.tier.tokens_rate
      end

      it 'updates reloaded_at' do
        expect(api_key.reloaded_at).to eq Date.today
      end
    end

    context 'when update_reloaded_at is false' do
      let!(:api_key) { create(:api_key) }

      before do
        api_key.tokens.destroy_all
        api_key.update(reloaded_at: 1.month.ago - 1.day)
        token_reloader.reload_tokens(update_reloaded_at: false)
        api_key.reload
      end

      it 'does not update reloaded_at' do
        expect(api_key.reloaded_at).to eq((1.month.ago - 1.day).to_date)
      end
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
        described_class.reload_active_keys
        expect(user.active_api_keys.first.available_tokens).to be_empty
      end

      it 'does not reload expired keys' do
        described_class.reload_active_keys
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
        described_class.reload_active_keys
        expect(user.active_api_keys.first.available_tokens.count).to eq(user.role.tier.tokens_rate)
      end

      it 'does not reload expired keys' do
        described_class.reload_active_keys
        expect(user2.api_keys.first.expired?).to be(true)
        expect(user2.api_keys.first.tokens.count).to eq 0
      end
    end
  end
end
