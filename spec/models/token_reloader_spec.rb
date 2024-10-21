require 'rails_helper'

RSpec.describe TokenReloader, type: :model do
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

      it 'reloads active keys' do
        described_class.reload_active_keys
        expect(user.active_api_keys.first.available_tokens.count).to eq(user.role.tier.tokens_rate)
      end

      it 'updates reloaded_at' do
        described_class.reload_active_keys
        expect(user.active_api_keys.first.reloaded_at).to eq(Date.today)
      end

      it 'does not reload expired keys' do
        described_class.reload_active_keys
        expect(user2.api_keys.first.expired?).to be(true)
        expect(user2.api_keys.first.tokens.count).to eq 0
      end
    end
  end
end
