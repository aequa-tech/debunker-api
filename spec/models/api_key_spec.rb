# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiKey, type: :model do
  let(:user) { create(:user) }
  subject(:api_key) { create(:api_key, user:) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:tokens).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:access_token) }
    it { should validate_uniqueness_of(:access_token) }
    it { should validate_presence_of(:secret_token) }
    it { should validate_presence_of(:user) }
  end

  describe 'active' do
    it 'returns active api keys' do
      expect(ApiKey.active).to include(api_key)
    end
  end

  describe 'usk' do
    it 'returns a string combining access_token and user email' do
      expect(ApiKey.usk(api_key.access_token, user)).to eq("#{api_key.access_token}%#{user.email}")
    end
  end

  describe 'authenticate!' do
    context 'when the api key is valid' do
      it 'returns the authenticated user' do
        key_pair = ApiKey.generate_key_pair
        api_key = create(:api_key, access_token: key_pair[:access_token], secret_token: key_pair[:secret_token], user:)

        result = ApiKey.authenticate!(key_pair[:access_token], key_pair[:secret_token])
        aggregate_failures do
          expect(result).to be_a(User)
          expect(result.id).to eq api_key.user.id
        end
      end
    end

    context 'when authentication fails' do
      context 'when the api key is invalid' do
        it 'returns false' do
          expect(ApiKey.authenticate!('invalid', 'invalid')).to be false
        end
      end

      context 'having the wrong secret' do
        let(:key_pair) { ApiKey.generate_key_pair }
        let!(:api_key) do
          create(:api_key, access_token: key_pair[:access_token], secret_token: key_pair[:secret_token], user:)
        end

        it 'returns false' do
          expect(ApiKey.authenticate!(key_pair[:access_token], 'invalid')).to be false
        end
      end
    end
  end

  describe 'generate_key_pair' do
    it 'returns a hash with access_token and secret_token' do
      key_pair = ApiKey.generate_key_pair
      expect(key_pair.keys).to contain_exactly(:access_token, :secret_token)
    end
  end

  describe '#encode_secret' do
    it 'encodes the secret_token' do
      expect(api_key.secret_token).not_to eq(ApiKey.usk(api_key.access_token, user))
    end
  end

  describe '#masked_secret' do
    it 'returns a masked version of the secret_token' do
      expect(api_key.masked_secret).to match(/\A.{9}\*{8}\z/)
    end
  end

  describe 'create a new api key' do
    context 'when no previous api key exists' do
      it 'create tokens from tier' do
        expect(api_key.tokens.available.count).to eq(user.role.tier.tokens_rate)
        expect(api_key.reloaded_at).to eq(Date.today)
      end
    end

    context 'when a previous api key exists' do
      it 'create api key with old available tokens number and previous reloaded_at' do
        old_api_key = create(:api_key, user:)
        old_api_key.tokens.first(2).each(&:finish!)

        old_count = old_api_key.available_tokens.count
        old_reloaded_at = old_api_key.reloaded_at

        new_api_key = create(:api_key, user:)
        expect(new_api_key.tokens.count).to eq(old_count)
        expect(new_api_key.reloaded_at).to eq(old_reloaded_at)
      end
    end

    it 'only one active api key per user' do
      api_key
      expect(ApiKey.where(user:).active.count).to eq(1)
      create(:api_key, user:)
      expect(ApiKey.where(user:).active.count).to eq(1)
    end
  end
end
