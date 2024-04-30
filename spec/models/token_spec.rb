# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Token, type: :model do
  let(:api_key) { create(:api_key) }
  let(:token) { create(:token, api_key:) }

  describe 'associations' do
    it { should belong_to(:api_key) }
  end

  describe 'validations' do
    it { should validate_presence_of(:value) }
    it 'value is unique' do
      create(:token, value: '123', api_key:)
      token = build(:token, value: '123', api_key: create(:api_key))
      expect(token).not_to be_valid
    end
  end

  describe 'available' do
    it 'returns available tokens' do
      expect(Token.available).to include(token)
    end
  end

  describe '#available?' do
    it 'returns true if the token is available' do
      expect(token.available?).to be_truthy
    end
  end

  describe '#free!' do
    it 'frees the token' do
      token.free!
      expect(token.used_on).to be_nil
    end
  end

  describe '#occupy!' do
    it 'occupies the token' do
      url = 'http://example.com'
      token.occupy!(url)
      expect(token.used_on).to eq(url)
    end
  end

  describe '#temporary_response!' do
    it 'updates the support_response_object' do
      payload = { key: 'value' }
      token.temporary_response!(payload)
      expect(token.support_response_object).to eq(payload.to_json)
    end
  end

  describe '#try!' do
    it 'increments the retries count' do
      expect { token.try! }.to change { token.retries }.by(1)
    end
  end

  describe '#consume!' do
    it 'destroys the token' do
      token
      expect { token.consume! }.to change { Token.count }.by(-1)
    end
  end
end
