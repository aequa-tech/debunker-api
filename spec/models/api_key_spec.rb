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
      it 'returns true' do
        key_pair = ApiKey.generate_key_pair
        create(:api_key, access_token: key_pair[:access_token], secret_token: key_pair[:secret_token], user:)
        expect(ApiKey.authenticate!(key_pair[:access_token], key_pair[:secret_token])).to be_truthy
      end
    end

    context 'when the api key is invalid' do
      it 'returns false' do
        expect(ApiKey.authenticate!('invalid', 'invalid')).to be_falsey
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
    it 'create free tokens' do
      expect(api_key.tokens.available.count).to eq(ENV.fetch('FREE_TOKENS_REGISTRATION').to_i)
    end
  end
end
